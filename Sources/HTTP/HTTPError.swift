import Foundation

public enum HTTPError: Error {
    
    // URL Error
    public enum URLErrorReason {
        case invalidScheme(String?)
        case invalidHost(String?)
        case invalidPort(Int?)
        
        case malformedComponents(URLComponents)
    }
    case URL(URLErrorReason)
    
    // Request Error
    public enum RequestErrorReason {
        case missingURL
        case invalidResumeData(Data)
        
        case missingUploadBody
    }
    case request(RequestErrorReason)
    
    
    // Response Error
    public enum ResponseErrorReason {
        
        case badResponse(String?)
    }
    case response(ResponseErrorReason)
    
    // Client Error
    case session(Error)
    
    case jsonSerialization(Data, Error)
    
    case custom(Error)
}

extension HTTPError {
    
    public var custom: Error? {
        guard case .custom(let e) = self else {
            return nil
        }
        return e
    }
}

extension Error {
    
    public func asHTTPError() -> HTTPError {
        if let e = self as? HTTPError {
            return e
        }
        return .custom(self)
    }
}

extension HTTPError: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .URL(let reason):
            var r = ""
            switch reason {
            case .invalidScheme(let s): r = "Invalid Scheme: (\(s as Any))"
            case .invalidHost(let h):   r = "Invalid Host: (\(h as Any))"
            case .invalidPort(let p):   r = "Invalid Port: (\(p as Any))"
            case .malformedComponents(let comps):
                r = "Malformed Components: (\(comps))"
            }
            return "[HTTPError]: URL > \(r)"
        default:
            return "\(self)"
        }
    }
}
