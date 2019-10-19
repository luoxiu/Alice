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
    
    // MARK: Body
    
//    public var jsonBody: Any? {
//        get {
//            switch self.body {
//            case .data(let data):
//                return try? JSONSerialization.jsonObject(with: data, options: [])
//            case .file(let file):
//
//                return try? JSONSerialization.jsonObject(with: InputStream(url: <#T##URL#>), options: <#T##JSONSerialization.ReadingOptions#>)
//            }
//        }
//    }
    
    
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
    
    public func with(_ body: (inout HTTPRequest) -> Void) -> HTTPRequest {
        var request = self
        body(&request)
        return request
    }
    
    public func withMethod(_ method: HTTPMethod) -> HTTPRequest {
        return self.with {
            $0.method = method
        }
    }
    
    public func withURL(_ url: HTTPURL) -> HTTPRequest {
        return self.with {
            $0.url = url
        }
    }
    
    public func withHeaders(_ headers: HTTPHeaders) -> HTTPRequest {
        return self.with {
            $0.headers = headers
        }
    }
    
    public func withBody(_ body: HTTPRequestBody) -> HTTPRequest {
        return self.with {
            $0.body = body
        }
    }
    
    public func withCachePolicy(_ cachePolicy: HTTPRequest.CachePolicy) -> HTTPRequest {
        return self.with {
            $0.cachePolicy = cachePolicy
        }
    }
    
    public func withTimeoutInterval(_ timeoutInterval: TimeInterval) -> HTTPRequest {
        return self.with {
            $0.timeoutInterval = timeoutInterval
        }
    }
    
    public func withAllowsCellularAccess(_ allowsCellularAccess: Bool) -> HTTPRequest {
        return self.with {
            $0.allowsCellularAccess = allowsCellularAccess
        }
    }
    
    public func withHttpShouldHandleCookies(_ httpShouldHandleCookies: Bool) -> HTTPRequest {
        return self.with {
            $0.httpShouldHandleCookies = httpShouldHandleCookies
        }
    }
    
    public func withHttpShouldUsePipelining(_ httpShouldUsePipelining: Bool) -> HTTPRequest {
        return self.with {
            $0.httpShouldUsePipelining = httpShouldUsePipelining
        }
    }
    
    public func withNetworkServiceType(_ networkServiceType: HTTPRequest.NetworkServiceType) -> HTTPRequest {
        return self.with {
            $0.networkServiceType = networkServiceType
        }
    }
}


extension HTTPRequest {
    
    public func toURLRequest() throws -> URLRequest {
        let url = try self.url.toURL()
        
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
    
    public init(_ urlRequest: URLRequest) throws {
        guard let url = urlRequest.url else {
            throw HTTPError.request(.missingURL)
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
    
    public init(_ resumeData: Data) throws {
        
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

extension HTTPRequest {
    
    public func dataTask() -> HTTPTask {
        return HTTPTask(HTTPClient.shared, self, .data)
    }
    
    public func downloadTask() -> HTTPTask {
        return HTTPTask(HTTPClient.shared, self, .download)
    }
    
    public func uploadTask() -> HTTPTask {
        return HTTPTask(HTTPClient.shared, self, .upload)
    }
    
    public func send() -> HTTPTask {
        let task = self.dataTask()
        task.start()
        return task
    }
}
