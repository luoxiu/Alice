import Foundation

public enum HTTPStringMatch: ExpressibleByStringLiteral {
    case exist
    case exact(String)
    case regexp(String)
    case custom((String) -> Bool)
    
    public init(stringLiteral value: String) {
        self = .regexp(value)
    }
    
    public func matches(_ value: String) -> Bool {
        switch self {
        case .exist:                return true
        case .exact(let s):         return s == value
        case .regexp(let pattern):
            guard let regexp = try? NSRegularExpression(pattern: pattern, options: []) else {
                return false
            }
            return regexp.matches(in: value, options: [], range: NSRange(location: 0, length: value.ns.length)).count != 0
        case .custom(let body):     return body(value)
        }
    }
}

public struct HTTPRequestMatch {
    
    private let match: (HTTPRequest) -> Bool
    
    public func matches(_ request: HTTPRequest) -> Bool {
        return self.match(request)
    }
    
    public init(_ match: @escaping (HTTPRequest) -> Bool) {
        self.match = match
    }
    
    public func and(_ others: HTTPRequestMatch...) -> HTTPRequestMatch {
        return HTTPRequestMatch { (request) -> Bool in
            guard self.match(request) else {
                return false
            }
            
            for match in others {
                guard match.matches(request) else {
                    return false
                }
            }
            return true
        }
    }
    
    public static func methods(_ methods: HTTPMethod...) -> HTTPRequestMatch {
        return HTTPRequestMatch {
            methods.contains($0.method)
        }
    }
    
    public func methods(_ methods: HTTPMethod...) -> HTTPRequestMatch {
        return self.and(.methods(methods))
    }
    
    public static func methods(_ methods: [HTTPMethod]) -> HTTPRequestMatch {
        return HTTPRequestMatch {
            methods.contains($0.method)
        }
    }
    
    public func methods(_ methods: [HTTPMethod]) -> HTTPRequestMatch {
        return self.and(.methods(methods))
    }
    
    public static func header(name: HTTPHeaderName, match: HTTPStringMatch) -> HTTPRequestMatch {
        return HTTPRequestMatch {
            guard let value = $0.headers.value(for: name) else {
                return false
            }
            return match.matches(value)
        }
    }
    
    public func header(name: HTTPHeaderName, match: HTTPStringMatch) -> HTTPRequestMatch {
        return self.and(.header(name: name, match: match))
    }
    
    public static func host(_ host: String) -> HTTPRequestMatch {
        let hostMatch = HTTPStringMatch.regexp(host)
        return HTTPRequestMatch {
            guard let host = $0.url.host else {
                return false
            }
            return hostMatch.matches(host)
        }
    }
    
    public func host(_ host: String) -> HTTPRequestMatch {
        return self.and(.host(host))
    }
    
    public static func path(_ path: String) -> HTTPRequestMatch {
        let pathMatch = HTTPStringMatch.regexp(path)
        return HTTPRequestMatch {
            return pathMatch.matches($0.url.path)
        }
    }
    
    public func path(_ path: String) -> HTTPRequestMatch {
        return self.and(.path(path))
    }
}
