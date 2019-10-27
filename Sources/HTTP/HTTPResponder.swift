import Foundation
import Async

public protocol HTTPResponder {
    
    func respond(to request: HTTPRequest) throws -> Future<HTTPResponse, HTTPError>
}

public struct HTTPAnyResponder: HTTPResponder {
    
    private let body: (HTTPRequest) throws -> Future<HTTPResponse, HTTPError>

    public init(_ body: @escaping (HTTPRequest) throws -> Future<HTTPResponse, HTTPError>) {
        self.body = body
    }
    
    public func respond(to reqeust: HTTPRequest) throws -> Future<HTTPResponse, HTTPError> {
        return try body(reqeust)
    }
}
