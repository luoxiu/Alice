import Foundation

public protocol Matcher {
    
    associatedtype Target
    
    func matches(_ target: Target?) -> Bool
    
    init(_ matcher: @escaping (Target?) -> Bool)
}

extension Matcher {
    
    public func or(_ matchers: Self...) -> Self {
        return Self { target in
            if self.matches(target) {
                return true
            }
            for m in matchers {
                if m.matches(target) {
                    return true
                }
            }
            return false
        }
    }
    
    public func and(_ matchers: Self...) -> Self {
        return Self { target in
            guard self.matches(target) else {
                return false
            }
            for m in matchers {
                guard m.matches(target) else {
                    return false
                }
            }
            return true
        }
    }
}

public struct StringMatcher: Matcher, ExpressibleByStringLiteral {
    
    private let matcher: (String?) -> Bool
    
    public init(_ matcher: @escaping (String?) -> Bool) {
        self.matcher = matcher
    }
    
    public func matches(_ string: String?) -> Bool {
        return self.matcher(string)
    }
    
    public init(stringLiteral value: String) {
        self = .regexp(value)
    }
    
    public static func exist() -> StringMatcher {
        return StringMatcher {
            return $0 != nil
        }
    }
    
    public static func exact(_ string: String) -> StringMatcher {
        return StringMatcher {
            return $0 == string
        }
    }
    
    public static func regexp(_ pattern: String) -> StringMatcher {
        return StringMatcher {
            guard let target = $0 else {
                return false
            }
            guard let regexp = try? NSRegularExpression(pattern: pattern, options: []) else {
                return false
            }
            return regexp.matches(in: target, options: [], range: NSRange(location: 0, length: target.ns.length)).count != 0
        }
    }
}

public struct HTTPRequestMatcher: Matcher {
    
    private let matcher: (HTTPRequest?) -> Bool
    
    public init(_ matcher: @escaping (HTTPRequest?) -> Bool) {
        self.matcher = matcher
    }
    
    public func matches(_ request: HTTPRequest?) -> Bool {
        return self.matcher(request)
    }
    
    public static func methods(_ methods: HTTPMethod...) -> HTTPRequestMatcher {
        return HTTPRequestMatcher {
            guard let target = $0 else { return false }
            return methods.contains(target.method)
        }
    }
    
    public func methods(_ methods: HTTPMethod...) -> HTTPRequestMatcher {
        return self.and(.methods(methods))
    }
    
    public static func methods(_ methods: [HTTPMethod]) -> HTTPRequestMatcher {
        return HTTPRequestMatcher {
            guard let target = $0 else { return false }
            return methods.contains(target.method)
        }
    }
    
    public func methods(_ methods: [HTTPMethod]) -> HTTPRequestMatcher {
        return self.and(.methods(methods))
    }
    
    public static func header(name: HTTPHeaderName, match: StringMatcher) -> HTTPRequestMatcher {
        return HTTPRequestMatcher {
            guard let value = $0?.headers.value(for: name) else {
                return false
            }
            return match.matches(value)
        }
    }
    
    public func header(name: HTTPHeaderName, match: StringMatcher) -> HTTPRequestMatcher {
        return self.and(.header(name: name, match: match))
    }
    
    public static func host(_ host: String) -> HTTPRequestMatcher {
        let hostMatch = StringMatcher.regexp(host)
        return HTTPRequestMatcher {
            guard let host = $0?.url.host else {
                return false
            }
            return hostMatch.matches(host)
        }
    }
    
    public func host(_ host: String) -> HTTPRequestMatcher {
        return self.and(.host(host))
    }
    
    public static func path(_ path: String) -> HTTPRequestMatcher {
        let pathMatch = StringMatcher.regexp(path)
        return HTTPRequestMatcher {
            guard let path = $0?.url.path else {
                return false
            }
            return pathMatch.matches(path)
        }
    }
    
    public func path(_ path: String) -> HTTPRequestMatcher {
        return self.and(.path(path))
    }
}
