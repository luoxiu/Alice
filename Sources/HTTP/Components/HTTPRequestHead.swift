import Foundation

public struct HTTPRequestHead {
    
    private final class Storage {
        var method: HTTPMethod
        var url: HTTPURL
        var headers: HTTPHeaders
        
        init(method: HTTPMethod, url: HTTPURL, headers: HTTPHeaders) {
            self.method = method
            self.url = url
            self.headers = headers
        }
        
        func copy() -> Storage {
            return Storage(method: method, url: url, headers: headers)
        }
    }
    
    private var storage: Storage
    
    public init(method: HTTPMethod, url: HTTPURL, headers: HTTPHeaders) {
        self.storage = Storage(method: method, url: url, headers: headers)
    }
    
    public var method: HTTPMethod {
        get { return self.storage.method }
        set {
            if !isKnownUniquelyReferenced(&self.storage) {
                self.storage = self.storage.copy()
            }
            self.storage.method = newValue
        }
    }
    
    public var url: HTTPURL {
        get { return self.storage.url }
        set {
            if !isKnownUniquelyReferenced(&self.storage) {
                self.storage = self.storage.copy()
            }
            self.storage.url = newValue
        }
    }
    
    public var headers: HTTPHeaders {
        get { return self.storage.headers }
        set {
            if !isKnownUniquelyReferenced(&self.storage) {
                self.storage = self.storage.copy()
            }
            self.storage.headers = newValue
        }
    }
}
