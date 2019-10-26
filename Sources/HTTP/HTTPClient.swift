import Foundation
import Async
import Utility

open class HTTPClient {
    
    private var taskRegistry: [URLSessionTask: HTTPTask]
    private var middlewares: [HTTPMiddleware]
    
    private let workQueue: DispatchQueue
    
    public let session: URLSession

    public init(configuration: URLSessionConfiguration) {
        self.taskRegistry = [:]
        self.middlewares = []
        self.workQueue = DispatchQueue(label: UUID().uuidString, attributes: .concurrent)
        
        let sessionDelegate = Delegate()
        
        self.session = URLSession(
            configuration: configuration,
            delegate: sessionDelegate,
            delegateQueue: nil
        )
        
        sessionDelegate.client = self
    }
    
    public convenience init() {
        let conf = URLSessionConfiguration.default
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            conf.waitsForConnectivity = true
        }
        self.init(configuration: conf)
    }
    
    deinit {
        self.session.invalidateAndCancel()
    }
    
    func register(_ httpTask: HTTPTask, for sessionTask: URLSessionTask) {
        self.workQueue.async(flags: .barrier) {
            self.taskRegistry[sessionTask] = httpTask
        }
    }
    
    func unregister(_ httpTask: HTTPTask, for sessionTask: URLSessionTask) {
        self.workQueue.async(flags: .barrier) {
            self.taskRegistry[sessionTask] = nil
        }
    }
    
    func httpTask(for sessionTask: URLSessionTask, _ body: (HTTPTask) -> Void) {
        if let task = self.workQueue.sync(execute: { self.taskRegistry[sessionTask] }) {
            body(task)
        }
    }
    
    open func getAllTasks(on scheduler: Scheduler) -> Future<[HTTPTask], Never> {
        let promise = Promise<[HTTPTask], Never>()
        
        self.workQueue.async {
            promise.succeed(Array(self.taskRegistry.values))
        }
        
        return promise.future.yield(on: scheduler)
    }
    
    // MARK: - Middleware
    @discardableResult
    open func use(_ middleware: HTTPMiddleware) -> Self {
        self.workQueue.async(flags: .barrier) {
            self.middlewares.append(middleware)
        }
        return self
    }
    
    @discardableResult
    open func use(_ middleware: @escaping (HTTPRequest, HTTPResponder) -> Future<HTTPResponse, Error>) -> Self {
        self.workQueue.async(flags: .barrier) {
            self.middlewares.append(HTTPAnyMiddleware(middleware))
        }
        return self
    }
    
    @discardableResult
    open func use(_ middleware: HTTPMiddleware, when matcher: HTTPRequestMatcher) -> Self {
        let new = HTTPAnyMiddleware { (request, responder) in
            if matcher.matches(request) {
                return try middleware.respond(to: request, chainingTo: responder)
            } else {
                return try responder.respond(to: request)
            }
        }
        return self.use(new)
    }
    
    open func getAllMiddlewares(on scheduler: Scheduler) -> Future<[HTTPMiddleware], Never> {
        let promise = Promise<[HTTPMiddleware], Never>()
        
        self.workQueue.async {
            promise.succeed(self.middlewares)
        }
        
        return promise.future.yield(on: scheduler)
    }
    
    // MARK: - Request
    open func request(_ request: HTTPRequest) -> HTTPTask {
        return HTTPTask(self, request, .data)
    }
    
    open func download(_ request: HTTPRequest, to location: URL?) -> HTTPTask {
        return HTTPTask(self, request, location)
    }
    
    open func get(_ url: HTTPURL) -> HTTPTask {
        return HTTPTask(self, HTTPRequest(method: .get, url: url), .data, true)
    }
    
    open func get(_ url: String) -> HTTPTask {
        return HTTPTask(self, HTTPRequest(method: .get, url: HTTPURL(url)), .data, true)
    }
    
    // MARK: - Shared
    open class var shared: HTTPClient {
        enum Shared {
            static let client = HTTPClient()
        }
        return Shared.client
    }
}


// MARK: - Delegate

extension HTTPClient {
    
    private class Delegate: NSObject, URLSessionDataDelegate, URLSessionDownloadDelegate {
        
        private var unmanagedClient: Unmanaged<HTTPClient>?
        
        var client: HTTPClient? {
            get { return self.unmanagedClient?.takeUnretainedValue() }
            set {
                if let client = newValue {
                    self.unmanagedClient = .passUnretained(client)
                    return
                }
                self.unmanagedClient = nil
            }
        }
        
        // MARK: URLSessionDelegate
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        }
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            completionHandler(.performDefaultHandling, nil)
        }
        
        #if !os(macOS)
        func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
            
        }
        #endif
        
 
        // MARK: URLSessionTaskDelegate
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, needNewBodyStream: completionHandler)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, didFinishCollecting: metrics)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, didCompleteWithError: error)
            }
        }
        
        @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
        func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
            
            self.client?.httpTask(for: task) {
                $0.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
            }
        }
        
        // MARK: URLSessionDataDelegate
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
             
            self.client?.httpTask(for: dataTask) {
                $0.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {

            self.client?.httpTask(for: dataTask) {
                $0.urlSession(session, dataTask: dataTask, didBecome: downloadTask)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

            self.client?.httpTask(for: dataTask) {
                $0.urlSession(session, dataTask: dataTask, didReceive: data)
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {

            self.client?.httpTask(for: dataTask) {
                $0.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
            }
        }
        
        // MARK: URLSessionDownloadDelegate
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            
            self.client?.httpTask(for: downloadTask) {
                $0.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            
            self.client?.httpTask(for: downloadTask) {
                $0.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
            
            self.client?.httpTask(for: downloadTask) {
                $0.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
            }
        }
    }
}
