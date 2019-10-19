import Foundation

public protocol HTTPRequestConvertible {
    
    func toHTTPRequest() throws -> HTTPRequest
}

extension HTTPRequest: HTTPRequestConvertible {
    
    public func toHTTPRequest() throws -> HTTPRequest {
        return self
    }
}

extension URLRequest: HTTPRequestConvertible {
    
    public func toHTTPRequest() throws -> HTTPRequest {
        return try HTTPRequest(self)
    }
}

extension Data: HTTPRequestConvertible {
    
    public func toHTTPRequest() throws -> HTTPRequest {
        return try HTTPRequest(self)
    }
}
