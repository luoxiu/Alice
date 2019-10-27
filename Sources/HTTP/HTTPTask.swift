import Foundation
import Async
import Utility

open class HTTPTask {
    
    fileprivate enum State: UInt8 {
        case initialized = 0x10
        case processingRequest = 0x20
        case loading = 0x30
        case processingResponse = 0x40
        case finished = 0x50
    }
    
    fileprivate let workQueue: DispatchQueue
    
    fileprivate var state: State
    fileprivate var middlewares: [HTTPMiddleware]
    
    public let client: HTTPClient
    public let request: HTTPRequest
    fileprivate let sessionResponder: HTTPSessionResponder
    fileprivate let promise: Promise<HTTPResponse, HTTPError>
    
    public typealias ProgressCallback = (HTTPProgress) -> Void
    fileprivate var whenUploadProgressUpdate: (Scheduler, ProgressCallback)?
    fileprivate var whenDownloadProgressUpdate: (Scheduler, ProgressCallback)?
    
    fileprivate var sessionTask: URLSessionTask?
    fileprivate var urlResponse: URLResponse?
    fileprivate var metrics: URLSessionTaskMetrics?
    
    init(_ client: HTTPClient, _ request: HTTPRequest, startImmediately: Bool = true) {
        self.workQueue = DispatchQueue(label: UUID().uuidString)
        self.state = .initialized
        self.middlewares = []
        
        self.client = client
        self.request = request
        
        self.promise = Promise()

        self.sessionResponder = HTTPSessionResponder()
        self.sessionResponder.httpTask = self
        
        if startImmediately {
            self.start()
        }
    }
    
    open var response: Future<HTTPResponse, HTTPError> {
        return self.promise.future
    }
    
    // MARK: Middleware
    @discardableResult
    open func use(_ middleware: HTTPMiddleware) -> Self {
        self.workQueue.async {
            guard self.state == .initialized else { return }
            self.middlewares.append(middleware)
        }
        return self
    }
    
    @discardableResult
    open func use(_ middleware: @escaping (HTTPRequest, HTTPResponder) -> Future<HTTPResponse, HTTPError>) -> Self {
        self.workQueue.async {
            guard self.state == .initialized else { return }
            self.middlewares.append(HTTPAnyMiddleware(middleware))
        }
        return self
    }
    
    func getAllMiddlewares(on scheduler: Scheduler) -> Future<[HTTPMiddleware], Never> {
        let promise = Promise<[HTTPMiddleware], Never>()
        
        self.workQueue.async {
            promise.succeed(self.middlewares)
        }
        
        return promise.future.yield(on: scheduler)
    }
    
    // MARK: Progress
    open func whenUploadProgressUpdate(scheduler: Scheduler, _ callback: @escaping ProgressCallback) -> Self {
        self.workQueue.async {
            self.whenUploadProgressUpdate = (scheduler, callback)
        }
        return self
    }
    
    open func whenDownloadProgressUpdate(scheduler: Scheduler, _ callback: @escaping ProgressCallback) -> Self  {
        self.workQueue.async {
            self.whenDownloadProgressUpdate = (scheduler, callback)
        }
        return self
    }
    
    public func start() {
        self.client.getAllMiddlewares(on: self.workQueue)
            .whenSucceed { clientMiddlewares in
                guard self.state == .initialized else { return }
                
                self.state = .processingRequest
                
                let responder = (clientMiddlewares + self.middlewares).makeResponder(chainingTo: self.sessionResponder)
                do {
                    try responder.respond(to: self.request).pipe(to: self.promise)
                } catch let e {
                    self.state = .finished
                    self.promise.fail(e.asHTTPError())
                }
            }
    }
    
    public func suspend() {
        self.workQueue.async {
            self.sessionTask?.suspend()
        }
    }
    
    public func resume() {
        self.workQueue.async {
            self.sessionTask?.resume()
        }
    }
    
    public func cancel() {
        self.workQueue.async {
            self.state = .finished
            self.sessionTask?.cancel()
        }
    }

    // MARK: - Delegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            self.client.unregister(self, for: task)
        }
        
        self.workQueue.async {
            guard self.state != .finished else {
                return
            }
            
            if let error = error {
                self.state = .finished
                self.sessionResponder.fail(.session(error))
                return
            }
            
            self.state = .processingResponse
            guard let response = task.response as? HTTPURLResponse, let metrics = self.metrics else {
                self.sessionResponder.fail(.response(.badResponse("impossible")))
                return
            }
            
            var body = HTTPResponseBody.none
            
            switch self {
            case let downloadTask as HTTPDownloadTask:
                body = .file(downloadTask.location)
            case let dataTask as HTTPDataTask:
                body = .data(dataTask.data)
            default: break
            }
            
            self.sessionResponder.succeed(HTTPResponse(response, body, metrics))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        completionHandler(self.request.body.stream)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.workQueue.async {
            let progress = HTTPProgress(totalUnitCount: totalBytesExpectedToSend, completedUnitCount: totalBytesSent)
            if let action = self.whenUploadProgressUpdate {
                action.0.schedule {
                    action.1(progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics = metrics
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        completionHandler(.continueLoading, nil)
    }

}

open class HTTPDataTask: HTTPTask {
    
    fileprivate var data = Data()
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.urlResponse = response
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        // not supported yet
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data.append(data)

        let total = self.urlResponse?.expectedContentLength ?? 0
        let completed = self.data.count
        let progress = HTTPProgress(totalUnitCount: total, completedUnitCount: Int64(completed))
        
        self.workQueue.async {
            if let action = self.whenDownloadProgressUpdate {
                action.0.schedule {
                    action.1(progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }
}

open class HTTPUploadTask: HTTPDataTask { }

open class HTTPDownloadTask: HTTPTask {
    
    public let location: URL
    
    public init(_ client: HTTPClient, _ request: HTTPRequest, _ location: URL, startImmediately: Bool = true) {
        self.location = location
        super.init(client, request, startImmediately: startImmediately)
    }
    
    open func cancelByProducingResumeData(on scheduler: Scheduler) -> Future<Data?, Never> {
        let promise = Promise<Data?, Never>()
        self.workQueue.async {
            guard let task = self.sessionTask as? URLSessionDownloadTask else {
                return
            }
            task.cancel {
                promise.succeed($0)
            }
        }
        return promise.future.yield(on: scheduler)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.moveItem(at: location, to: self.location)
        } catch {
            self.workQueue.async {
                self.state = .finished
                self.sessionResponder.fail(.response(.canNotMoveDownloadedFile(error)))
            }
        }
    }
       
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
       
       self.workQueue.async {
           let progress = HTTPProgress(totalUnitCount: expectedTotalBytes, completedUnitCount: fileOffset)
           if let action = self.whenDownloadProgressUpdate {
               action.0.schedule {
                   action.1(progress)
               }
           }
       }
    }
       
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
       
       self.workQueue.async {
           let progress = HTTPProgress(totalUnitCount: totalBytesExpectedToWrite, completedUnitCount: totalBytesWritten)
            if let action = self.whenDownloadProgressUpdate {
                action.0.schedule {
                    action.1(progress)
                }
            }
       }
    }
}

extension HTTPTask {
    
    enum Kind {
       case data, upload, download
   }
    
    var kind: Kind {
        switch self {
        case is HTTPDownloadTask:   return .download
        case is HTTPUploadTask:     return .upload
        default:                    return .data
        }
    }
}

extension HTTPTask {
    
    fileprivate final class HTTPSessionResponder: HTTPResponder {
        
        unowned var httpTask: HTTPTask!
        
        private let promise: Promise<HTTPResponse, HTTPError>
        
        init() {
            self.promise = Promise()
        }
        
        func respond(to request: HTTPRequest) throws -> Future<HTTPResponse, HTTPError> {
            let task = try self.sessionTask(for: request)
            self.httpTask.client.register(self.httpTask, for: task)
            task.resume()
            return self.promise.future
        }
        
        func succeed(_ response: HTTPResponse) {
            self.promise.succeed(response)
        }
        
        func fail(_ error: HTTPError) {
            self.promise.fail(error)
        }
        
        private func sessionTask(for request: HTTPRequest) throws -> URLSessionTask {
            let session = self.httpTask.client.session
            
            let urlRequest = try request.toURLRequest()
            
            switch httpTask.kind {
            case .data:
                return session.dataTask(with: urlRequest)
            case .upload:
                switch request.body {
                case .none:
                    throw HTTPError.request(.badRequest("body not found in upload request"))
                case .data(let data):
                    return session.uploadTask(with: urlRequest, from: data)
                case .file(let url):
                    return session.uploadTask(with: urlRequest, fromFile: url)
                case .stream:
                    return session.uploadTask(withStreamedRequest: urlRequest)
                }
            case .download:
                switch request.resumeData {
                case .none:
                    return session.downloadTask(with: urlRequest)
                case .some(let data):
                    return session.downloadTask(withResumeData: data)
                }
            }
        }
    }

}
