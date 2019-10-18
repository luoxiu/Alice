import Foundation

public struct HTTPResponseHead {

    private final class Storage {
        
        var url: HTTPURL
        var status: HTTPResponseStatus
        var headers: HTTPHeaders
        
        init(url: HTTPURL, status: HTTPResponseStatus, headers: HTTPHeaders) {
            self.url = url
            self.status = status
            self.headers = headers
        }
        
        func copy() -> Storage {
            return Storage(url: url, status: status, headers: headers)
        }
    }
    
    private var storage: Storage
    
    public init(url: HTTPURL, status: HTTPResponseStatus, headers: HTTPHeaders) {
        self.storage = Storage(url: url, status: status, headers: headers)
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
    
    public var status: HTTPResponseStatus {
        get { return self.storage.status }
        set {
            if !isKnownUniquelyReferenced(&self.storage) {
                self.storage = self.storage.copy()
            }
            self.storage.status = newValue
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
