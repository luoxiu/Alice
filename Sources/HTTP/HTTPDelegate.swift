import Foundation

// MARK: - Typealias

// Session
public typealias SessionDidBecomeInvalidWithErrorCallback = (
    _ session: URLSession,
    _ error: Error?
    ) -> Void

public typealias SessionDidReceiveChallengeCallback = (
    _ session: URLSession,
    _ challenge: URLAuthenticationChallenge,
    _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) -> Void

public typealias SessionDidFinishEventsCallback = (
    _ session: URLSession
    ) -> Void

// Task
@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
public typealias TaskWillBeginDelayedRequestCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ request: URLRequest,
    _ completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void
    ) -> Void

@available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
public typealias TaskIsWaitingForConnectivityCallback = (
    _ session: URLSession,
    _ task: URLSessionTask
    ) -> Void

public typealias TaskWillPerformHTTPRedirectionCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ response: HTTPURLResponse,
    _ newRequest: URLRequest,
    _ completionHandler: @escaping (URLRequest?) -> Void
    ) -> Void

public typealias TaskDidReceiveChallengeCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ challenge: URLAuthenticationChallenge,
    _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) -> Void

public typealias TaskNeedNewBodyStreamCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ completionHandler: @escaping (InputStream?) -> Void
    ) -> Void

public typealias TaskDidSendBodyDataCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ bytesSent: Int64,
    _ totalBytesSent: Int64,
    _ totalBytesExpectedToSend: Int64
    ) -> Void

public typealias TaskDidFinishCollectingMetricsCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ metrics: URLSessionTaskMetrics
    ) -> Void

public typealias TaskDidCompleteWithErrorCallback = (
    _ session: URLSession,
    _ task: URLSessionTask,
    _ error: Error?
    ) -> Void

// Data Task
public typealias DataTaskDidReceiveResponseCallback = (
    _ session: URLSession,
    _ dataTask: URLSessionDataTask,
    _ response: URLResponse,
    _ completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) -> Void

public typealias DataTaskDidBecomeDownloadTaskCallback = (
    _ session: URLSession,
    _ dataTask: URLSessionDataTask,
    _ downloadTask: URLSessionDownloadTask
    ) -> Void

public typealias DataTaskDidReceiveDataCallback = (
    _ session: URLSession,
    _ dataTask: URLSessionDataTask,
    _ data: Data
    ) -> Void

public typealias DataTaskWillCacheResponseCallback = (
    _ session: URLSession,
    _ dataTasK: URLSessionDataTask,
    _ proposedResponse: CachedURLResponse,
    _ completionHandler: @escaping (CachedURLResponse?) -> Void
    ) -> Void


// Download Task
public typealias DownloadTaskDidFinishDownloadingToLocationCallback = (
    _ session: URLSession,
    _ downloadTask: URLSessionDownloadTask,
    _ location: URL
) -> Void

public typealias DownloadTaskDidWriteDataCallback = (
    _ session: URLSession,
    _ downloadTask: URLSessionDownloadTask,
    _ bytesWritten: Int64,
    _ totalBytesWritten: Int64,
    _ totalBytesExpectedToWrite: Int64
) -> Void

public typealias DownloadTaskDidResumeAtOffsetCallback = (
    _ session: URLSession,
    _ downloadTask: URLSessionDownloadTask,
    _ fileOffset: Int64,
    _ expectedTotalBytes: Int64
) -> Void

public class HTTPTaskDelegate {
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    public var taskWillBeginDelayedRequestCallback: TaskWillBeginDelayedRequestCallback? {
        get { return self._taskWillBeginDelayedRequestCallback as? TaskWillBeginDelayedRequestCallback }
        set { self._taskWillBeginDelayedRequestCallback = newValue }
    }
    
    public var _taskWillBeginDelayedRequestCallback: Any?
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    public var taskIsWaitingForConnectivityCallback: TaskIsWaitingForConnectivityCallback? {
        get { return self._taskIsWaitingForConnectivityCallback as? TaskIsWaitingForConnectivityCallback }
        set { self._taskIsWaitingForConnectivityCallback = newValue }
    }
    
    public var _taskIsWaitingForConnectivityCallback: Any?
    
    public var taskWillPerformHTTPRedirectionCallback: TaskWillPerformHTTPRedirectionCallback?
    
    public var taskDidReceiveChallengeCallback: TaskDidReceiveChallengeCallback?
    
    public var taskNeedNewBodyStreamCallback: TaskNeedNewBodyStreamCallback?
    
    public var taskDidSendBodyDataCallback: TaskDidSendBodyDataCallback?
    
    public var taskDidFinishCollectingMetricsCallback: TaskDidFinishCollectingMetricsCallback?
    
    public var taskDidCompleteWithErrorCallback: TaskDidCompleteWithErrorCallback?
    
    public var dataTaskDidReceiveResponseCallback: DataTaskDidReceiveResponseCallback?
    
    public var dataTaskDidBecomeDownloadTaskCallback: DataTaskDidBecomeDownloadTaskCallback?
    
    public var dataTaskDidReceiveDataCallback: DataTaskDidReceiveDataCallback?
    
    public var dataTaskWillCacheResponseCallback: DataTaskWillCacheResponseCallback?
    
    public var downloadTaskDidFinishDownloadingToLocationCallback: DownloadTaskDidFinishDownloadingToLocationCallback?
    
    public var downloadTaskDidWriteDataCallback: DownloadTaskDidWriteDataCallback?
    
    public var downloadTaskDidResumeAtOffsetCallback: DownloadTaskDidResumeAtOffsetCallback?
}

public class HTTPSessionDelegate: HTTPTaskDelegate {
    
    public var sessionDidBecomeInvalidWithErrorCallback: SessionDidBecomeInvalidWithErrorCallback?
    
    public var sessionDidReceiveChallengeCallback: SessionDidReceiveChallengeCallback?
    
    public var sessionDidFinishEventsCallback: SessionDidFinishEventsCallback?
}

public protocol HTTPTaskDelegating {
    var taskDelegate: HTTPTaskDelegate { get }
    var nextTaskDelegating: HTTPTaskDelegating? { get }
}

public protocol HTTPSessionDelegating: HTTPTaskDelegating {
    
    var sessionDelegate: HTTPSessionDelegate { get }
}

extension HTTPTaskDelegating {
    
    public var nextTaskDelegating: HTTPTaskDelegating? {
        return nil
    }
}

extension HTTPSessionDelegating {
    
    public var taskDelegate: HTTPTaskDelegate {
        return self.sessionDelegate
    }
}

public extension HTTPSessionDelegating {
    
    func onSessionDidBecomeInvalidWithError(_ callback: @escaping SessionDidBecomeInvalidWithErrorCallback) -> Self {
        self.sessionDelegate.sessionDidBecomeInvalidWithErrorCallback = callback
        return self
    }
    
    func onSessionDidReceiveChallenge(_ callback: @escaping SessionDidReceiveChallengeCallback) -> Self {
        self.sessionDelegate.sessionDidReceiveChallengeCallback = callback
        return self
    }
    
    func onSessionDidFinishEvents(_ callback: @escaping SessionDidFinishEventsCallback) -> Self {
        self.sessionDelegate.sessionDidFinishEventsCallback = callback
        return self
    }
}

public extension HTTPTaskDelegating {
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func onTaskWillBeginDelayedRequest(_ callback: @escaping TaskWillBeginDelayedRequestCallback) -> Self {
        self.taskDelegate.taskWillBeginDelayedRequestCallback = callback
        return self
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func onTaskIsWaitingForConnectivity(_ callback: @escaping TaskIsWaitingForConnectivityCallback) -> Self {
        self.taskDelegate.taskIsWaitingForConnectivityCallback = callback
        return self
    }
    
    func onTaskWillPerformHTTPRedirection(_ callback: @escaping TaskWillPerformHTTPRedirectionCallback) -> Self {
        self.taskDelegate.taskWillPerformHTTPRedirectionCallback = callback
        return self
    }
    
    func onTaskDidReceiveChallenge(_ callback: @escaping TaskDidReceiveChallengeCallback) -> Self {
        self.taskDelegate.taskDidReceiveChallengeCallback = callback
        return self
    }
    
    func onTaskNeedNewBodyStream(_ callback: @escaping TaskNeedNewBodyStreamCallback) -> Self {
        self.taskDelegate.taskNeedNewBodyStreamCallback = callback
        return self
    }
    
    func onTaskDidSendBodyData(_ callback: @escaping TaskDidSendBodyDataCallback) -> Self {
        self.taskDelegate.taskDidSendBodyDataCallback = callback
        return self
    }
    
    func onTaskDidFinishCollectingMetrics(_ callback: @escaping TaskDidFinishCollectingMetricsCallback) -> Self {
        self.taskDelegate.taskDidFinishCollectingMetricsCallback = callback
        return self
    }
    
    func onTaskDidCompleteWithError(_ callback: @escaping TaskDidCompleteWithErrorCallback) -> Self {
        self.taskDelegate.taskDidCompleteWithErrorCallback = callback
        return self
    }
    
    func onDataTaskDidReceiveResponse(_ callback: @escaping DataTaskDidReceiveResponseCallback) -> Self {
        self.taskDelegate.dataTaskDidReceiveResponseCallback = callback
        return self
    }
    
    func onDataTaskDidBecomeDownloadTask(_ callback: @escaping DataTaskDidBecomeDownloadTaskCallback) -> Self {
        self.taskDelegate.dataTaskDidBecomeDownloadTaskCallback = callback
        return self
    }
    
    func onDataTaskDidReceiveData(_ callback: @escaping DataTaskDidReceiveDataCallback) -> Self {
        self.taskDelegate.dataTaskDidReceiveDataCallback = callback
        return self
    }
    
    func onDataTaskWillCacheResponse(_ callback: @escaping DataTaskWillCacheResponseCallback) -> Self {
        self.taskDelegate.dataTaskWillCacheResponseCallback = callback
        return self
    }
    
    func onDownloadTaskDidFinishDownloadingToLocation(_ callback: @escaping DownloadTaskDidFinishDownloadingToLocationCallback) -> Self {
        self.taskDelegate.downloadTaskDidFinishDownloadingToLocationCallback = callback
        return self
    }
    
    func onDownloadTaskDidWriteData(_ callback: @escaping DownloadTaskDidWriteDataCallback) -> Self {
        self.taskDelegate.downloadTaskDidWriteDataCallback = callback
        return self
    }
    
    func onDownloadTaskDidResumeAtOffset(_ callback: @escaping DownloadTaskDidResumeAtOffsetCallback) -> Self {
        self.taskDelegate.downloadTaskDidResumeAtOffsetCallback = callback
        return self
    }
}
