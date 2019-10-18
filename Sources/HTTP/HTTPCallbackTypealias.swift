import Foundation

public typealias SessionDidReceiveChallengeCallback = (
    _ session: URLSession,
    _ challenge: URLAuthenticationChallenge,
    _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
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

public typealias DataTaskDidReceiveResponseCallback = (
    _ session: URLSession,
    _ dataTask: URLSessionDataTask,
    _ response: URLResponse,
    _ completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) -> Void

public typealias DataTaskWillCacheResponseCallback = (
    _ session: URLSession,
    _ dataTasK: URLSessionDataTask,
    _ proposedResponse: CachedURLResponse,
    _ completionHandler: @escaping (CachedURLResponse?) -> Void
    ) -> Void
