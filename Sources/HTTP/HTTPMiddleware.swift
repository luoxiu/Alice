import Foundation
import Async

public protocol HTTPMiddleware {
    
    func respond(to req: HTTPRequest, chainingTo next: HTTPResponder) throws -> Future<HTTPResponse, HTTPError>
}

public struct HTTPAnyMiddleware: HTTPMiddleware {
    
    private let body: (_ req: HTTPRequest, _ next: HTTPResponder) throws -> Future<HTTPResponse, HTTPError>
    
    public init(_ body: @escaping (_ req: HTTPRequest, _ next: HTTPResponder) throws -> Future<HTTPResponse, HTTPError>) {
        self.body = body
    }
    
    public func respond(to req: HTTPRequest, chainingTo next: HTTPResponder) throws -> Future<HTTPResponse, HTTPError> {
        return try body(req, next)
    }
}

extension HTTPMiddleware {
    
    func makeResponder(chainingTo responder: HTTPResponder) -> HTTPResponder {
        return HTTPAnyResponder {
            return try self.respond(to: $0, chainingTo: responder)
        }
    }
}

extension Sequence where Element == HTTPMiddleware {
    
    func makeResponder(chainingTo responder: HTTPResponder) -> HTTPResponder {
        var responder = responder
        for middlware in reversed() {
            responder = middlware.makeResponder(chainingTo: responder)
        }
        return responder
    }
}
