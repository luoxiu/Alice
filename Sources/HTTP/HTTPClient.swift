import Foundation
import Utility

open class HTTPClient {
    
    // MARK: - Properties
    
    let workQueue: DispatchQueue
    private let syncQueue: DispatchQueue
    
    public let session: URLSession
    
    private var _taskRegistry: [URLSessionTask: HTTPTask]
    private var _middlewares: Bag<HTTPMiddleware>
    
    // MARK: - Init
    public init(configuration: URLSessionConfiguration) {
        self.workQueue = DispatchQueue(label: UUID().uuidString)
        self.syncQueue = DispatchQueue(label: UUID().uuidString)
        
        self._taskRegistry = [:]
        self._middlewares = Bag()
        
        let sessionDelegate = HTTPClientDelegate()
        
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
    
    // MARK: - Methods
    
    func register(_ httpTask: HTTPTask, for sessionTask: URLSessionTask) {
        self.syncQueue.async {
            self._taskRegistry[sessionTask] = httpTask
        }
    }
    
    func unregister(_ httpTask: HTTPTask, for sessionTask: URLSessionTask) {
        self.syncQueue.async {
            self._taskRegistry[sessionTask] = nil
        }
    }
    
    func httpTask(for sessionTask: URLSessionTask, _ body: @escaping (HTTPTask) -> Void) {
        self.syncQueue.async {
            if let t = self._taskRegistry[sessionTask] {
                self.workQueue.async {
                    body(t)
                }
            }
        }
    }
    
    open var allTasks: [HTTPTask] {
        return self.syncQueue.sync {
            Array(self._taskRegistry.values)
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
    
    @discardableResult
    open func use(_ mw: @escaping (HTTPRequest, HTTPResponder) -> Future<HTTPResponse, Error>) -> Self {
        self.syncQueue.async {
            self._middlewares.append(HTTPAnyMiddleware(mw))
        }
        return self
    }
    
    @discardableResult
    open func use(_ mw: HTTPMiddleware, _ token: inout BagToken) -> Self {
        self.syncQueue.sync {
            token = self._middlewares.append(mw)
        }
        return self
    }
    
    @discardableResult
    open func use(_ mw: HTTPMiddleware, when matcher: HTTPRequestMatcher) -> Self {
        let new = HTTPAnyMiddleware { (request, responder) in
            if matcher.matches(request) {
                return try mw.respond(to: request, chainingTo: responder)
            } else {
                return try responder.respond(to: request)
            }
        }
        return self.use(new)
    }
    
    open func removeMiddleware(for token: BagToken) -> HTTPMiddleware? {
        return self.syncQueue.sync {
            self._middlewares.removeValue(for: token)
        }
    }
    
    open var middlewares: [HTTPMiddleware] {
        return self.syncQueue.sync {
            Array(self._middlewares)
        }
    }
    
    // MARK: - Send
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
    
    // MARK: - URLSessionDelegate

    // MARK: session
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        self.workQueue.async {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    }

    // MARK: task
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, needNewBodyStream: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, didFinishCollecting: metrics)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        
        self.httpTask(for: task) {
            $0.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
        }
    }
    
    // MARK: data task
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self.httpTask(for: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        self.httpTask(for: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didBecome: downloadTask)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        self.httpTask(for: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        self.httpTask(for: dataTask) {
            $0.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
    }
    
    // MARK: download task
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        self.httpTask(for: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        self.httpTask(for: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        self.httpTask(for: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        }
    }
}
