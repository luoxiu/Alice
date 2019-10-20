import Foundation

public enum HTTPScheme: String {
    case http
    case https
    
    public var isHTTPS: Bool {
        return self == .https
    }
}

extension HTTPScheme: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .http:     return "[HTTPScheme]: http"
        case .https:    return "[HTTPScheme]: https"
        }
    }
}

// MARK: - Extensions

extension String {
    
    public func toHTTPScheme() -> Result<HTTPScheme, HTTPError> {
        if let scheme = HTTPScheme(rawValue: self) {
            return .success(scheme)
        }
        return .failure(.URL(.invalidScheme(self)))
    }
    
    public var isValidHTTPScheme: Bool {
        return HTTPScheme(rawValue: self) != nil
    }
}
