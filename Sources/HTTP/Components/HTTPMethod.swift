public enum HTTPMethod: RawRepresentable, Hashable {

    case get
    case head
    case post
    case put
    case delete
    case connect
    case options
    case trace
    case patch
    
    case custom(String)

    public var rawValue: String {
        switch self {
        case .get:              	return "GET"
        case .head:             	return "HEAD"
        case .post:             	return "POST"
        case .put:              	return "PUT"
        case .delete:               return "DELETE"
        case .connect:              return "CONNECT"
        case .options:          	return "OPTIONS"
        case .trace:                return "TRACE"
        case .patch:                return "PATCH"
        case .custom(let method):   return method
        }
    }

    public init(rawValue: String) {
        let uppercased = rawValue.uppercased()
        switch uppercased {
        case "GET":     self = .get
        case "HEAD":    self = .head
        case "POST":    self = .post
        case "PUT":     self = .put
        case "DELETE":  self = .delete
        case "CONNECT": self = .connect
        case "OPTIONS": self = .options
        case "TRACE":   self = .trace
        case "PATCH":   self = .patch
        default:        self = .custom(uppercased)
        }
    }
}

extension HTTPMethod: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}
