import Foundation
import Async

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
