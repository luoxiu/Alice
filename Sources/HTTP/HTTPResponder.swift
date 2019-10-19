import Foundation
import Async

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPResponder {
    
    func respond(to request: HTTPRequest) throws -> Future<HTTPResponse, Error>
}

public struct HTTPAnyResponder: HTTPResponder {
    
    private let body: (HTTPRequest) throws -> Future<HTTPResponse, Error>

    public init(_ body: @escaping (HTTPRequest) throws -> Future<HTTPResponse, Error>) {
        self.body = body
    }
    
    public func respond(to reqeust: HTTPRequest) throws -> Future<HTTPResponse, Error> {
        return try body(reqeust)
    }
}

final class HTTPSessionResponder: HTTPResponder {
    
    weak var httpTask: HTTPTask!
    
    private let responsePromise: Promise<HTTPResponse, Error>
    
    init() {
        self.responsePromise = Promise()
    }
    
    func respond(to request: HTTPRequest) throws -> Future<HTTPResponse, Error> {
        let task = try self.makeSessionTask(for: request)
        self.httpTask.client.register(self.httpTask, for: task)
        task.resume()
        
        return responsePromise.future
    }
    
    func succeed(_ response: HTTPResponse) {
        self.responsePromise.succeed(response)
    }
    
    func fail(_ error: HTTPError) {
        self.responsePromise.fail(error)
    }
    
    private func makeSessionTask(for request: HTTPRequest) throws -> URLSessionTask {
        let session = self.httpTask.session
        
        let urlRequest = try request.toURLRequest()
        
        switch httpTask.kind {
        case .data:
            return session.dataTask(with: urlRequest)
        case .upload:
            switch request.body {
            case .none:
                throw HTTPError.request(.missingUploadBody)
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
