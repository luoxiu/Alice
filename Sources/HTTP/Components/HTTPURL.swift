import Foundation

public struct HTTPURL {

    private var components: URLComponents
    
    public init() {
        self.components = URLComponents()
        self.scheme = .http
    }
    
    public var scheme: HTTPScheme? {
        get {
            return self.components.scheme?.toHTTPScheme()
        }
        set {
            self.components.scheme = newValue?.rawValue
        }
    }
    
    public var username: String? {
        get {
            return self.components.user
        }
        set {
            self.components.user = newValue
        }
    }
    
    public var password: String? {
        get {
            return self.components.password
        }
        set {
            self.components.password = newValue
        }
    }
    
    public var host: String? {
        get {
            return self.components.host
        }
        set {
            self.components.host = newValue
        }
    }
    
    public var port: Int? {
        get {
            return self.components.port
        }
        set {
            self.components.port = newValue
        }
    }
    
    public var path: String {
        get {
            return self.components.path
        }
        set {
            self.components.path = newValue
        }
    }
    
    public var pathComponents: [String] {
        get {
            return (self.components.path as NSString).pathComponents
        }
        set {
            self.components.path = NSString.path(withComponents: newValue)
        }
    }
    
    public mutating func appendPathComponent(_ component: String) {
        self.path = self.path.ns.appendingPathComponent(component)
    }
    
    public var queryString: String? {
        get {
            return self.components.query
        }
        set {
            self.components.query = newValue
        }
    }
    
    public var query: HTTPQuery? {
        get {
            guard let items = self.components.queryItems else {
                return nil
            }
            return HTTPQuery(queryItems: items)
        }
        set {
            self.components.queryItems = newValue?.toQueryItems()
        }
    }
    
    public var fragment: String? {
        get {
            return self.components.fragment
        }
        set {
            self.components.fragment = newValue
        }
    }
    
    // MARK: - chainable api
    public func with(_ body: (inout HTTPURL) -> Void) -> HTTPURL {
        var url = self
        body(&url)
        return url
    }
    
    public func withScheme(_ scheme: HTTPScheme) -> HTTPURL {
        var url = self
        url.scheme = scheme
        return self
    }
    
    public func withUsername(_ username: String) -> HTTPURL {
        var url = self
        url.username = username
        return url
    }
    
    public func withPassword(_ password: String) -> HTTPURL {
        var url = self
        url.password = password
        return url
    }
    
    public func withHost(_ host: String) -> HTTPURL {
        var url = self
        url.host = host
        return url
    }
    
    public func withPort(_ port: Int) -> HTTPURL {
        var url = self
        url.port = port
        return url
    }
    
    public func withPath(_ path: String) -> HTTPURL {
        var url = self
        url.path = path
        return url
    }
    
    public func withPathComponents(_ pathComponents: [String]) -> HTTPURL {
        var url = self
        url.pathComponents = pathComponents
        return url
    }
    
    public func withQueryString(_ query: String) -> HTTPURL {
        var url = self
        url.queryString = query
        return url
    }
    
    public func withQuery(_ query: HTTPQuery) -> HTTPURL {
        var url = self
        url.query = query
        return url
    }
    
    public func withFragment(_ fragment: String) -> HTTPURL {
        var url = self
        url.fragment = fragment
        return url
    }
}

extension HTTPURL {
    
    public init(_ string: String) {
        self.components = URLComponents(string: string) ?? URLComponents()
    }
    
    public init(_ url: URL) {
        self.components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
    }
}

extension HTTPURL {
    
    public var isValid: Bool {
        return (try? self.toURL()) != nil
    }
    
    public func toURL() throws -> URL {
        guard let scheme = self.components.scheme else {
            throw HTTPError.url(.missingScheme)
        }
        
        guard scheme.isValidHTTPScheme else {
            throw HTTPError.url(.invalidScheme(scheme))
        }
        
        if self.components.host == nil {
            throw HTTPError.url(.missingHost)
        }
        
        if let port = self.components.port {
            guard (0..<65535).contains(port) else {
                throw HTTPError.url(.invalidPort(port))
            }
        }
        
        guard let url = self.components.url else {
            throw HTTPError.url(.malformedComponents(self.components))
        }
        
        return url
    }
}

extension HTTPURL {
    
    public var isHTTPS: Bool {
        return self.components.scheme == HTTPScheme.https.rawValue
    }
}

extension HTTPURL: CustomStringConvertible {
    
    public var description: String {
        if let url = try? self.toURL() {
            return url.description
        } else {
            // todo: output error description
            return "[HTTPURL] Invalid URL(\(self.components))"
        }
    }
}
