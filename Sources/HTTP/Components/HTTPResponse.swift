import Foundation

public struct HTTPResponse {
    
    public var head: HTTPResponseHead
    
    public var body: HTTPResponseBody
    
    private var properties: Properties
    
    public var metrics: URLSessionTaskMetrics
    
    init(_ response: HTTPURLResponse, _ body: HTTPResponseBody, _ metrics: URLSessionTaskMetrics) {
        guard let url = response.url else {
            preconditionFailure(#"HTTPRepsonse's url should always be a valid "HTTPURL"."#)
        }
        
        let httpURL = url.toHTTPURL()
        
        self.head = HTTPResponseHead(url: httpURL, status: HTTPResponseStatus(code: response.statusCode), headers: .of(response))
        self.body = body
        self.metrics = metrics
        
        var mimeType: HTTPMIMEType?
        if let rawString = response.mimeType {
            mimeType = HTTPMIMEType(rawString: rawString)
        }
        
        var textEncoding: String.Encoding?
        if let encodingName = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            textEncoding = String.Encoding(rawValue: nsEncoding)
        }
        
        self.properties = Properties(expectedContentLength: response.expectedContentLength, suggestedFilename: response.suggestedFilename, mimeType: mimeType, textEncoding: textEncoding)
    }
    
    public var url: HTTPURL {
        get { return self.head.url }
        set {
            self.head.url = newValue
        }
    }
    
    public var status: HTTPResponseStatus {
        get { return self.head.status }
        set {
            self.head.status = newValue
        }
    }
    
    public var statusCode: Int {
        return self.status.code
    }
    
    public var statusMessage: String {
        return self.status.message
    }
    
    public var headers: HTTPHeaders {
        get { return self.head.headers }
        set {
            self.head.headers = newValue
        }
    }
    
    public var expectedContentLenght: Int64 {
        get { return self.properties.expectedContentLength }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.expectedContentLength = newValue
        }
    }
    
    public var suggestedFilename: String? {
        get { return self.properties.suggestedFilename }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.suggestedFilename = newValue
        }
    }
    
    public var mimeType: HTTPMIMEType? {
        get { return self.properties.mimeType }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.mimeType = newValue
        }
    }
    
    public var textEncoding: String.Encoding? {
        get { return self.properties.textEncoding }
        set {
            if !isKnownUniquelyReferenced(&self.properties) {
                self.properties = self.properties.copy()
            }
            self.properties.textEncoding = newValue
        }
    }
    
}

extension HTTPResponse {
    
    // MARK: - Chainable
    
    public func mURL(_ url: HTTPURL) -> HTTPResponse {
        var response = self
        response.url = url
        return response
    }
    
    public func mStatus(_ status: HTTPResponseStatus) -> HTTPResponse {
        var response = self
        response.status = status
        return response
    }
    
    public func mHeaders(_ headers: HTTPHeaders) -> HTTPResponse {
        var response = self
        response.headers = headers
        return response
    }
    
    public func mExpectedContentLenght(_ expectedContentLenght: Int64) -> HTTPResponse {
        var response = self
        response.expectedContentLenght = expectedContentLenght
        return response
    }
    
    public func mSuggestedFilename(_ suggestedFilename: String) -> HTTPResponse {
        var response = self
        response.suggestedFilename = suggestedFilename
        return response
    }
    
    public func mMIMEType(_ mimeType: HTTPMIMEType) -> HTTPResponse {
        var response = self
        response.mimeType = mimeType
        return response
    }
    
    public func mTextEncoding(_ textEncoding: String.Encoding) -> HTTPResponse {
        var response = self
        response.textEncoding = textEncoding
        return response
    }
}

extension HTTPResponse {
    
    private final class Properties {
        var expectedContentLength: Int64
        var suggestedFilename: String?
        var mimeType: HTTPMIMEType?
        var textEncoding: String.Encoding?
        
        init(expectedContentLength: Int64, suggestedFilename: String?, mimeType: HTTPMIMEType?, textEncoding: String.Encoding?) {
            self.expectedContentLength = expectedContentLength
            self.suggestedFilename = suggestedFilename
            self.mimeType = mimeType
            self.textEncoding = textEncoding
        }
        
        func copy() -> Properties {
            return Properties(expectedContentLength: self.expectedContentLength, suggestedFilename: self.suggestedFilename, mimeType: self.mimeType, textEncoding: self.textEncoding)
        }
    }
}

extension HTTPResponse {
    
    public var data: Any? {
        switch self.body {
        case .data(let data):
            return data
        default:
            return nil
        }
    }
    
    public var json: Any? {
        switch self.body {
        case .custom(let any):
            if JSONSerialization.isValidJSONObject(any) {
                return any
            } else {
                return nil
            }
        case .data(let data):
            return try? JSONSerialization.jsonObject(with: data, options: [])
        default:
            return nil
        }
    }
    
    public var string: Any? {
        switch self.body {
        case .custom(let any):
            if let str = any as? String {
                return str
            } else {
                return nil
            }
        case .data(let data):
            return String(bytes: data, encoding: .utf8)
        default:
            return nil
        }
    }
}
