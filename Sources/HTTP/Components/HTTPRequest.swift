import Foundation

public struct HTTPRequest {
    
    public var head: HTTPRequestHead
    public var body: HTTPRequestBody
    
    private var properties: Properties
    
    public var resumeData: Data?
    
    public typealias CachePolicy = URLRequest.CachePolicy
    public typealias NetworkServiceType = URLRequest.NetworkServiceType
    
    public init(head: HTTPRequestHead, body: HTTPRequestBody) {
        self.head = head
        self.body = body
        self.properties = Properties()
    }
    
    public init(method: HTTPMethod, url: HTTPURL) {
        self.head = HTTPRequestHead(method: method, url: url, headers: HTTPHeaders())
        self.body = .none
        self.properties = Properties()
    }
    
    // MARK: Head
    
    public var method: HTTPMethod {
        get { return self.head.method }
        set {
            self.head.method = newValue
        }
    }
    
    public var url: HTTPURL {
        get { return self.head.url }
        set {
            self.head.url = newValue
        }
    }
    
    public var headers: HTTPHeaders {
        get { return self.head.headers }
        set {
            self.head.headers = newValue
        }
    }
    
    // MARK: Configuration
    
    public var cachePolicy: HTTPRequest.CachePolicy {
        get { return self.properties.cachePolicy }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.cachePolicy = newValue
        }
    }
    
    public var timeoutInterval: TimeInterval {
        get { return self.properties.timeoutInterval }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.timeoutInterval = newValue
        }
    }
    
    public var allowsCellularAccess: Bool {
        get { return self.properties.allowsCellularAccess }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.allowsCellularAccess = newValue
        }
    }
    
    public var httpShouldHandleCookies: Bool {
        get { return self.properties.httpShouldHandleCookies }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.httpShouldHandleCookies = newValue
        }
    }
    
    public var httpShouldUsePipelining: Bool {
        get { return self.properties.httpShouldUsePipelining }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.httpShouldUsePipelining = newValue
        }
    }
    
    public var networkServiceType: HTTPRequest.NetworkServiceType {
        get { return self.properties.networkServiceType }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.networkServiceType = newValue
        }
    }
}

extension HTTPRequest {
    
    // MARK: - Chainable
    
    public func mMethod(_ method: HTTPMethod) -> HTTPRequest {
        var request = self
        request.method = method
        return request
    }
    
    public func mURL(_ URL: HTTPURL) -> HTTPRequest {
        var request = self
        request.url = URL
        return request
    }
    
    public func mURL(_ mutate: (inout HTTPURL) -> Void) -> HTTPRequest {
        var request = self
        mutate(&request.url)
        return request
    }
    
    public func mHeaders(_ headers: HTTPHeaders) -> HTTPRequest {
        var request = self
        request.headers = headers
        return request
    }
    
    public func mHeaders(_ mutate: (inout HTTPHeaders) -> Void) -> HTTPRequest {
        var request = self
        mutate(&request.headers)
        return request
    }
    
    public func mBody(_ body: HTTPRequestBody) -> HTTPRequest {
        var request = self
        request.body = body
        return request
    }
    
    public func mCachePolicy(_ cachePolicy: HTTPRequest.CachePolicy) -> HTTPRequest {
        var request = self
        request.cachePolicy = cachePolicy
        return request
    }
    
    public func mTimeoutInterval(_ timeoutInterval: TimeInterval) -> HTTPRequest {
        var request = self
        request.timeoutInterval = timeoutInterval
        return request
    }
    
    public func mAllowsCellularAccess(_ allowsCellularAccess: Bool) -> HTTPRequest {
        var request = self
        request.allowsCellularAccess = allowsCellularAccess
        return request
    }
    
    public func mHttpShouldHandleCookies(_ httpShouldHandleCookies: Bool) -> HTTPRequest {
        var request = self
        request.httpShouldHandleCookies = httpShouldHandleCookies
        return request
    }
    
    public func mHttpShouldUsePipelining(_ httpShouldUsePipelining: Bool) -> HTTPRequest {
        var request = self
        request.httpShouldUsePipelining = httpShouldUsePipelining
        return request
    }
    
    public func mNetworkServiceType(_ networkServiceType: HTTPRequest.NetworkServiceType) -> HTTPRequest {
        var request = self
        request.networkServiceType = networkServiceType
        return request
    }
}


extension HTTPRequest {
    
    func toURLRequest() throws -> URLRequest {
        let url = try self.url.toValidURL().get()
        
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = headers.toDictionary()
        switch self.body {
        case .none:             break
        case .data(let data):
            req.httpBody = data
        case .file(let url):
            req.httpBodyStream = InputStream(url: url)
        case .stream(let stream):
            req.httpBodyStream = stream
        }
        
        req.timeoutInterval = self.timeoutInterval
        req.allowsCellularAccess = self.allowsCellularAccess
        req.httpShouldHandleCookies = self.httpShouldHandleCookies
        req.httpShouldUsePipelining = self.httpShouldUsePipelining
        
        return req
    }
    
    init(_ urlRequest: URLRequest) throws {
        guard let url = urlRequest.url else {
            throw HTTPError.request(.badRequest("URL not found in URLRequest"))
        }
        
        let httpURL = url.toHTTPURL()
        
        var method = HTTPMethod.get
        if let raw = urlRequest.httpMethod {
            method = HTTPMethod(rawValue: raw)
        }
        
        let head = HTTPRequestHead(method: method, url: httpURL, headers: .of(urlRequest))
        let body: HTTPRequestBody
        if let data = urlRequest.httpBody {
            body = .data(data)
        } else if let stream = urlRequest.httpBodyStream {
            body = .stream(stream)
        } else {
            body = .none
        }
        
        self.init(head: head, body: body)
        self.cachePolicy = urlRequest.cachePolicy
        self.timeoutInterval = urlRequest.timeoutInterval
        self.allowsCellularAccess = urlRequest.allowsCellularAccess
        self.httpShouldHandleCookies = urlRequest.httpShouldHandleCookies
        self.httpShouldUsePipelining = urlRequest.httpShouldUsePipelining
    }
    
    init(_ resumeData: Data) throws {
        enum Lazy {
            static let session = URLSession(configuration: .default)
        }
        
        guard let req = Lazy.session.downloadTask(withResumeData: resumeData).currentRequest else {
            throw HTTPError.request(.invalidResumeData(resumeData))
        }
        
        try self.init(req)
        self.resumeData = resumeData
    }
}

extension HTTPRequest {
    
    private final class Properties {
        
        var cachePolicy = HTTPRequest.CachePolicy.useProtocolCachePolicy
        
        var timeoutInterval: TimeInterval = 60
        var allowsCellularAccess = true
        var httpShouldHandleCookies = true
        var httpShouldUsePipelining = true
        
        var networkServiceType = HTTPRequest.NetworkServiceType.default
        
        init() { }
        
        func copy() -> Properties {
            let storage = Properties()
            storage.cachePolicy = self.cachePolicy
            storage.timeoutInterval = self.timeoutInterval
            storage.allowsCellularAccess = self.allowsCellularAccess
            storage.httpShouldHandleCookies = self.httpShouldHandleCookies
            storage.httpShouldUsePipelining = self.httpShouldUsePipelining
            storage.networkServiceType = self.networkServiceType
            return storage
        }
    }
}
