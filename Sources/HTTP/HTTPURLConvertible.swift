import Foundation

public protocol HTTPURLConvertible {

    func toHTTPURL() -> HTTPURL
}

extension URL: HTTPURLConvertible {
    
    public func toHTTPURL() -> HTTPURL {
        return HTTPURL(self)
    }
}

extension String: HTTPURLConvertible {
    
    public func toHTTPURL() -> HTTPURL {
        return HTTPURL(self)
    }
}
