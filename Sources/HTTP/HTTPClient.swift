import Foundation
import Utility

open class HTTPClient {
    
    // MARK: - Properties
    
    let workQueue: DispatchQueue
    private let syncQueue: DispatchQueue
    
    public let session: URLSession
    
    private var _taskRegistry: [URLSessionTask: HTTPTask]
    private var _middlewares: Bag<HTTPMiddleware>
    
    private var _sessionDidReceiveChallengeCallback: SessionDidReceiveChallengeCallback?
    private var _taskWillPerformHTTPRedirectionCallback: TaskWillPerformHTTPRedirectionCallback?
    private var _taskDidReceiveChallengeCallback: TaskDidReceiveChallengeCallback?
    private var _dataTaskDidReceiveResponseCallback: DataTaskDidReceiveResponseCallback?
    private var _dataTaskWillCacheResponseCallback: DataTaskWillCacheResponseCallback?
    
    private weak var _delegate: HTTPClientDelegate?
    
    public var delegate: HTTPClientDelegate? {
        get { return self.syncQueue.sync { self._delegate } }
        set { self.syncQueue.async { self._delegate = newValue } }
    }
    
    // MARK: - Init
    public init(configuration: URLSessionConfiguration) {
        self.workQueue = DispatchQueue(label: UUID().uuidString)
        self.syncQueue = DispatchQueue(label: UUID().uuidString)
        
        self._taskRegistry = [:]
        self._middlewares = Bag()
        
        let sessionDelegate = HTTPSessionDelegate()
        
        self.session = URLSession(
            configuration: configuration,
            delegate: sessionDelegate,
            delegateQueue: nil
        )
        
        sessionDelegate.client = self
    }
    
    public convenience init() {
        let conf = URLSessionConfiguration.default
        if #available(OSX 10.13, *) {
            conf.waitsForConnectivity = true
        }
        self.init(configuration: conf)
    }
    
    deinit {
        self.session.invalidateAndCancel()
    }
    
    // MARK: - Methods
    
    // MARK: session
    
    open func onSessionDidReceiveChallenge(_ callback: @escaping SessionDidReceiveChallengeCallback) -> Self {
        self.syncQueue.async {
            self._sessionDidReceiveChallengeCallback = callback
        }
        return self
    }
    
    // MARK: task
    
    open func onTaskWillPerformHTTPRedirection(_ callback: @escaping TaskWillPerformHTTPRedirectionCallback) -> Self {
        self.syncQueue.async {
            self._taskWillPerformHTTPRedirectionCallback = callback
        }
        return self
    }
    
    open func onTaskDidReceiveChallenge(_ callback: @escaping TaskDidReceiveChallengeCallback) -> Self {
        self.syncQueue.async {
            self._taskDidReceiveChallengeCallback = callback
        }
        return self
    }
    
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
    
    func withHTTPTask(of sessionTask: URLSessionTask, _ body: @escaping (HTTPTask) -> Void) {
        self.syncQueue.async {
            if let t = self._taskRegistry[sessionTask] {
                body(t)
            }
        }
    }
    
    // MARK: data task
    
    open func onDataTaskDidReceiveResponse(_ callback: @escaping DataTaskDidReceiveResponseCallback) -> Self {
        self.syncQueue.async {
            self._dataTaskDidReceiveResponseCallback = callback
        }
        return self
    }
    
    open func onDataTaskWillCacheResponse(_ callback: @escaping DataTaskWillCacheResponseCallback) -> Self {
        self.syncQueue.async {
            self._dataTaskWillCacheResponseCallback = callback
        }
        return self
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
    open func use(_ mw: HTTPMiddleware, when match: HTTPRequestMatcher) -> Self {
        let new = HTTPAnyMiddleware { (request, responder) in
            if match.matches(request) {
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
    
    open func send(_ request: HTTPRequest) -> HTTPTask {
        return HTTPTask(self, request, .data)
    }

    // MARK: - Shared
    
    open class var shared: HTTPClient {
        enum Shared {
            static let client = HTTPClient()
        }
        return Shared.client
    }

    // MARK: - URLTaskDelegate Fallback
    
    func __urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        self.syncQueue.async {
            let callback = self._taskWillPerformHTTPRedirectionCallback
                ?? self._delegate?.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)
            
            if let callback = callback {
                self.workQueue.async {
                    callback(session, task, response, request, completionHandler)
                }
            } else {
                self.workQueue.async {
                    completionHandler(request)
                }
            }
        }
    }
    
    func __urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        self.syncQueue.async {
            let callback = self._taskDidReceiveChallengeCallback
                ?? self._delegate?.urlSession(_:task:didReceive:completionHandler:)
            
            if let callback = callback {
                self.workQueue.async {
                    callback(session, task, challenge, completionHandler)
                }
            } else {
                self.workQueue.async {
                    completionHandler(.performDefaultHandling, nil)
                }
            }
        }
    }
    
    func __urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self.syncQueue.async {
            let callback = self._dataTaskDidReceiveResponseCallback
                ?? self._delegate?.urlSession(_:dataTask:didReceive:completionHandler:)
            
            if let callback = callback {
                self.workQueue.async {
                    callback(session, dataTask, response, completionHandler)
                }
            } else {
                self.workQueue.async {
                    completionHandler(.allow)
                }
            }
        }
    }
    
    func __urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        self.syncQueue.async {
            let callback = self._dataTaskWillCacheResponseCallback
                ?? self._delegate?.urlSession(_:dataTask:willCacheResponse:completionHandler:)
            
            if let callback = callback {
                self.workQueue.async {
                    callback(session, dataTask, proposedResponse, completionHandler)
                }
            } else {
                self.workQueue.async {
                    completionHandler(proposedResponse)
                }
            }
        }
    }
    
    // MARK: - URLSessionDelegate

    // MARK: session
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        self.syncQueue.async {
            for (sessionTask, httpTask) in self._taskRegistry {
                httpTask.urlSession(session, task: sessionTask, didCompleteWithError: error)
            }
            self._taskRegistry.removeAll()
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        self.syncQueue.async {
            
            let callback = self._sessionDidReceiveChallengeCallback
                ?? self._delegate?.urlSession(_:didReceive:completionHandler:)
            
            if let callback = callback {
                self.workQueue.async {
                    callback(session, challenge, completionHandler)
                }
            } else {
                self.workQueue.async {
                    completionHandler(.performDefaultHandling, nil)
                }
            }
        }
    }
    
    
    #if !os(macOS)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    #endif

    // MARK: task
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, needNewBodyStream: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, didFinishCollecting: metrics)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        
        self.withHTTPTask(of: task) {
            $0.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
        }
    }
    
    // MARK: data task
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self.withHTTPTask(of: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        self.withHTTPTask(of: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didBecome: downloadTask)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        self.withHTTPTask(of: dataTask) {
            $0.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        self.withHTTPTask(of: dataTask) {
            $0.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
        }
    }
    
    // MARK: download task
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        self.withHTTPTask(of: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        self.withHTTPTask(of: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        self.withHTTPTask(of: downloadTask) {
            $0.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
        }
    }
}
