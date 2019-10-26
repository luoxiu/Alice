import Foundation
import Async
import Utility

extension HTTPTask {

    public enum Kind {
        case data
        case upload
        case download
    }
}

// TODO: Redesgin init part

open class HTTPTask {
    
    // MARK: - Properties
    
    let workQueue: DispatchQueue
    private let syncQueue: DispatchQueue
    
    private var _isStarted: Bool
    private var _kind: Kind
    
    private var _middlewares: [HTTPMiddleware]
    
    
    private var _uploadProgress = HTTPProgress(totalUnitCount: 0, completedUnitCount: 0)
    private var _downloadProgress = HTTPProgress(totalUnitCount: 0, completedUnitCount: 0)
    
    public typealias ProgressCallback = (HTTPProgress) -> Void
    private var uploadProgressCallback: ProgressCallback?
    private var downloadProgressCallback: ProgressCallback?
    
    // MARK: session
    public let client: HTTPClient
    public let request: HTTPRequest
    
    private let sessionResponder: HTTPSessionResponder
    
    private let responsePromise: Promise<HTTPResponse, Error>
    public let response: Future<HTTPResponse, Error>
    
    // MARK: task
    private var _sessionTask: URLSessionTask?
    private var _urlResponse: URLResponse?
    private var _metrics: URLSessionTaskMetrics?
    
    // MARK: data task
    private var _data: Data?
    
    // MARK: download task
    private var _url: URL?
    private var _downloadLocation: URL?
    
    // MARK: - Init
    init(_ client: HTTPClient, _ request: HTTPRequest, _ kind: Kind, _ startImmediately: Bool = false) {
        self._middlewares = []
        self._isStarted = false
        self._kind = kind
        
        self.client = client
        self.request = request
        
        self.responsePromise = Promise()
        self.response = self.responsePromise.future

        self.workQueue = DispatchQueue(label: UUID().uuidString)
        self.syncQueue = DispatchQueue(label: UUID().uuidString)
        
        self.sessionResponder = HTTPSessionResponder()
        self.sessionResponder.httpTask = self
        
        if startImmediately {
            self.start()
        }
    }
    
    convenience init(_ client: HTTPClient, _ request: HTTPRequest, _ downloadLocation: URL?) {
        self.init(client, request, .download)
        self._downloadLocation = downloadLocation
    }
    
    // MARK: - Methods
    
    open var isStarted: Bool {
        return self.syncQueue.sync {
            self._isStarted
        }
    }
    
    open var kind: Kind {
        return self.syncQueue.sync {
            self._kind
        }
    }
    
    // MARK: middlware
    @discardableResult
    open func use(_ mw: HTTPMiddleware) -> Self {
        self.syncQueue.async {
            self._middlewares.append(mw)
        }
        return self
    }
    
    open var middlewares: [HTTPMiddleware] {
        return self.syncQueue.sync {
            Array(self._middlewares)
        }
    }
    
    // MARK: progress
    open var uploadProgress: HTTPProgress {
        return self.syncQueue.sync {
            self._uploadProgress
        }
    }
    open var downloadProgress: HTTPProgress {
        return self.syncQueue.sync {
            self._downloadProgress
        }
    }
    
    open func onUploadProgress(_ callback: @escaping ProgressCallback) -> Self {
        self.uploadProgressCallback = callback
        return self
    }
    
    open func onDownloadProgress(_ callback: @escaping ProgressCallback) -> Self  {
        self.downloadProgressCallback = callback
        return self
    }

    // MARK: session
    open var session: URLSession {
        return self.client.session
    }
    
    // MARK: task
    open var sessionTask: URLSessionTask? {
        return self.syncQueue.sync {
            self._sessionTask
        }
    }
    
    open var uploadTask: URLSessionUploadTask? {
        return self.sessionTask as? URLSessionUploadTask
    }
    
    open var dataTask: URLSessionDataTask? {
        return self.sessionTask as? URLSessionDataTask
    }
    
    open var downloadTask: URLSessionDownloadTask? {
        return self.sessionTask as? URLSessionDownloadTask
    }
    
    public func start() {
        self.syncQueue.async {
            if self._isStarted {
                return
            }
            
            self._isStarted = true
            
            self.client
            .getAllMiddlewares(on: self.workQueue)
            .map { middlewares -> HTTPResponder in
                let allMiddlewares = middlewares + self.middlewares
                return allMiddlewares.makeResponder(chainingTo: self.sessionResponder)
            }
            .whenSucceed { responder in
                do {
                    try responder.respond(to: self.request).pipe(to: self.responsePromise)
                } catch let e {
                    self.responsePromise.fail(e)
                }
            }
        }
    }
    
    public func suspend() {
        if let task = self.sessionTask {
            task.suspend()
        }
    }
    
    public func resume() {
        if let task = self.sessionTask {
            task.resume()
        }
    }
    
    public func cancel() {
        if let task = self.sessionTask {
            task.cancel()
        }
    }
    
    // MARK: download task
    open func cancel(byProducingResumeData completionHandler: @escaping (Data?) -> Void) {
        self.downloadTask?.cancel(byProducingResumeData: {
            completionHandler($0)
        })
    }

    // MARK: - Delegate
    
    // MARK: task
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            self.client.unregister(self, for: task)
        }
        
        if let error = error {
            self.sessionResponder.fail(.session(error))
            return
        }
        
        guard let response = task.response as? HTTPURLResponse, let metrics = self._metrics else {
            self.sessionResponder.fail(.response(.badResponse("The response from the server should always be an http response.")))
            return
        }
        
        var body = HTTPResponseBody.none
        switch self.kind {
        case .download:
            if let url = self._url {
                body = .file(url)
            }
        case .data, .upload:
            if let data = self._data {
                body = .data(data)
            }
        }
        
        self.sessionResponder.succeed(HTTPResponse(response, body, metrics))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        completionHandler(self.request.body.stream)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = HTTPProgress(totalUnitCount: totalBytesExpectedToSend, completedUnitCount: totalBytesSent)
        self.syncQueue.async {
            self._uploadProgress = progress
            
            if let callback = self.uploadProgressCallback {
                self.workQueue.async {
                    callback(progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self._metrics = metrics
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        
        completionHandler(.continueLoading, nil)
    }
    
    // MARK: data task
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self._urlResponse = response
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        self.syncQueue.async {
            self._kind = .download
            self.workQueue.async {
                self.client.unregister(self, for: dataTask)
                self.client.register(self, for: downloadTask)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if self._data == nil {
            self._data = data
        } else {        
            self._data?.append(data)
        }
        
        let total = self._urlResponse?.expectedContentLength ?? 0
        let completed = self._data?.count ?? 0
        let progress = HTTPProgress(totalUnitCount: total, completedUnitCount: Int64(completed))
        
        self.syncQueue.async {
            self._downloadProgress = progress

            if let callback = self.downloadProgressCallback {
                self.workQueue.async {
                    callback(progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {

    }
    
    // MARK: download
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        if let downloadLocation = self._downloadLocation {
            do {
                try FileManager.default.moveItem(at: location, to: downloadLocation)
                self._url = downloadLocation
            } catch {
                self.sessionResponder.fail(.response(.canNotMoveDownloaded))
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        self.syncQueue.async {
            let progress = HTTPProgress(totalUnitCount: expectedTotalBytes, completedUnitCount: fileOffset)
            self._downloadProgress = progress
            
            if let callback = self.downloadProgressCallback {
                self.workQueue.async {
                    callback(progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        self.syncQueue.async {
            let progress = HTTPProgress(totalUnitCount: totalBytesExpectedToWrite, completedUnitCount: totalBytesWritten)
            self._downloadProgress = progress
            
            if let callback = self.downloadProgressCallback {
                self.workQueue.async {
                    callback(progress)
                }
            }
        }
    }
}

