import Foundation

class HTTPSessionDelegate: NSObject {
    
    weak var client: HTTPClient!
}

extension HTTPSessionDelegate: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        
        self.client.urlSession(session, didBecomeInvalidWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        self.urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
    
    
    #if !os(macOS)
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
        self.urlSessionDidFinishEvents(forBackgroundURLSession: session)
    }
    #endif
}

extension HTTPSessionDelegate: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        self.client.urlSession(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        self.client.urlSession(session, task: task, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        
        self.client.urlSession(session, task: task, needNewBodyStream: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        self.client.urlSession(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        self.client.urlSession(session, task: task, didFinishCollecting: metrics)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        self.client.urlSession(session, task: task, didCompleteWithError: error)
    }
    
    @available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        
        self.client.urlSession(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler)
    }
}

extension HTTPSessionDelegate: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        self.client.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        
        self.client.urlSession(session, dataTask: dataTask, didBecome: downloadTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        self.client.urlSession(session, dataTask: dataTask, didReceive: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        self.client.urlSession(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler)
    }
}

extension HTTPSessionDelegate: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        self.client.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        self.client.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        self.client.urlSession(session, downloadTask: downloadTask, didResumeAtOffset: fileOffset, expectedTotalBytes: expectedTotalBytes)
    }
}
