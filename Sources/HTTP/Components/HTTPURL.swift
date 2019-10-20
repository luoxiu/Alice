import Foundation

public struct HTTPURL {

    private var components: URLComponents
    
    public init() {
        self.components = URLComponents()
    }
    
    public init(_ string: String) {
        self.components = URLComponents(string: string) ?? URLComponents()
    }
    
    public init(_ URL: Foundation.URL) {
        self.components = URLComponents(url: URL, resolvingAgainstBaseURL: false) ?? URLComponents()
    }
    
    public var scheme: HTTPScheme? {
        get { return self.components.scheme?.toHTTPScheme().success }
        set { self.components.scheme = newValue?.rawValue }
    }
    
    public var username: String? {
        get { return self.components.user }
        set { self.components.user = newValue }
    }
    
    public var password: String? {
        get { return self.components.password }
        set { self.components.password = newValue }
    }
    
    public var host: String? {
        get { return self.components.host }
        set { self.components.host = newValue }
    }
    
    public var port: Int? {
        get { return self.components.port }
        set { self.components.port = newValue }
    }
    
    public var path: String {
        get { return self.components.path }
        set { self.components.path = newValue }
    }
    
    public var pathComponents: [String] {
        get { return self.path.ns.pathComponents }
        set { self.path = NSString.path(withComponents: newValue) }
    }
    
    public mutating func appendPathComponent(_ component: String) {
        self.path = self.path.ns.appendingPathComponent(component)
    }
    
    public var query: String? {
        get { return self.components.query }
        set { self.components.query = newValue }
    }
    
    public var httpQuery: HTTPQuery? {
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
        get { return self.components.fragment }
        set { self.components.fragment = newValue }
    }
}

extension HTTPURL {
    
    public var userinfo: String? {
        get {
            switch (self.username, self.password) {
            case (.some(let u), .some(let p)):  return "\(u):\(p)"
            case (.some(let u), .none):         return u
            case (.none, .some(let p)):         return ":\(p)"
            case (.none, .none):                return nil
            }
        }
        set {
            guard let userinfo = newValue else {
                self.username = nil
                self.password = nil
                return
            }
            let comps = userinfo.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if comps.count == 1 {
                self.username = comps[0].isEmpty ? nil : String(comps[0])
                self.password = nil
            } else if comps.count == 2 {
                self.username = comps[0].isEmpty ? nil : String(comps[0])
                self.password = comps[1].isEmpty ? nil : String(comps[1])
            }
        }
    }
}
    
// MARK: - Chainable

extension HTTPURL {
    
    public func mScheme(_ scheme: HTTPScheme) -> HTTPURL {
        var url = self
        url.scheme = scheme
        return self
    }
    
    public func mUsername(_ username: String) -> HTTPURL {
        var url = self
        url.username = username
        return url
    }
    
    public func mPassword(_ password: String) -> HTTPURL {
        var url = self
        url.password = password
        return url
    }
    
    public func mHost(_ host: String) -> HTTPURL {
        var url = self
        url.host = host
        return url
    }
    
    public func mPort(_ port: Int) -> HTTPURL {
        var url = self
        url.port = port
        return url
    }
    
    public func mPath(_ path: String) -> HTTPURL {
        var url = self
        url.path = path
        return url
    }
    
    public func mPathComponents(_ pathComponents: [String]) -> HTTPURL {
        var url = self
        url.pathComponents = pathComponents
        return url
    }
    
    public func mQuery(_ query: String) -> HTTPURL {
        var url = self
        url.query = query
        return url
    }
    
    public func mHTTPQuery(_ query: HTTPQuery) -> HTTPURL {
        var url = self
        url.httpQuery = query
        return url
    }
    
    public func mFragment(_ fragment: String) -> HTTPURL {
        var url = self
        url.fragment = fragment
        return url
    }
}

extension HTTPURL {
    
    public var isValid: Bool {
        return self.toValidURL().success != nil
    }
    
    public func toValidURL() -> Result<URL, HTTPError> {
        guard let scheme = self.components.scheme else {
            return .failure(.URL(.invalidScheme(nil)))
        }
        
        guard scheme.isValidHTTPScheme else {
            return .failure(.URL(.invalidScheme(scheme)))
        }
        
        if self.components.host == nil {
            return .failure(.URL(.invalidHost(nil)))
        }
        
        if let port = self.components.port {
            guard (0..<65535).contains(port) else {
                return .failure(.URL(.invalidPort(port)))
            }
        }
        
        guard let url = self.components.url else {
            return .failure(.URL(.malformedComponents(self.components)))
        }
        
        return .success(url)
    }
    
    public var url: URL? {
        return self.components.url
    }
    
    public var string: String? {
        return self.components.string
    }
    
    public var isHTTPS: Bool {
        return self.components.scheme == HTTPScheme.https.rawValue
    }
}

extension HTTPURL: CustomStringConvertible {
    
    public var description: String {
        switch self.toValidURL() {
        case .success(let URL):
            return "[HTTPURL]: \(URL.absoluteString)"
        case .failure:
            return "[HTTPURL]: Invalid URL(\(self.components))"
        }
    }
}

// MARK: - Extensions

extension URL {
    
    public var isValidHTTPURL: Bool {
        return HTTPURL(self).isValid
    }
}

extension String {
    
    public var isValidHTTPURL: Bool {
        return HTTPURL(self).isValid
    }
}
