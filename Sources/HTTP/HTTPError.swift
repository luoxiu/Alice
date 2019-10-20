import Foundation

public enum HTTPError: Error {
    
    public enum URLErrorReason {
        case invalidScheme(String?)
        case invalidHost(String?)
        case invalidPort(Int?)
        
        case malformedComponents(URLComponents)
    }
    
    case URL(URLErrorReason)
    
    public enum RequestErrorReason {
        case missingURL
        case invalidResumeData(Data)
        
        case missingUploadBody
    }
    
    case request(RequestErrorReason)
    
    
    case jsonSerialization(Data, Error)
    
    case session(Error)
    
    case teacup(String)
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
