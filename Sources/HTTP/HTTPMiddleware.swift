import Foundation
import Async

public protocol HTTPMiddleware {
    
    func respond(to req: HTTPRequest, chainingTo next: HTTPResponder) throws -> Future<HTTPResponse, Error>
}

public struct HTTPAnyMiddleware: HTTPMiddleware {
    
    private let body: (_ req: HTTPRequest, _ next: HTTPResponder) throws -> Future<HTTPResponse, Error>
    
    public init(_ body: @escaping (_ req: HTTPRequest, _ next: HTTPResponder) throws -> Future<HTTPResponse, Error>) {
        self.body = body
    }
    
    public func respond(to req: HTTPRequest, chainingTo next: HTTPResponder) throws -> Future<HTTPResponse, Error> {
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
