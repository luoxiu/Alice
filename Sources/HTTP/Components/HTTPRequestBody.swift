import Foundation

public enum HTTPRequestBody {
    
    case none
    case data(Data)
    case file(URL)
    case stream(InputStream)
}

extension HTTPRequestBody {
    
    public var data: Data? {
        get {
            guard case .data(let data) = self else {
                return nil
            }
            return data
        }
        set {
            if let data = newValue {
                self = .data(data)
            } else {
                self = .none
            }
        }
    }
    
    public var file: URL? {
        get {
            guard case .file(let url) = self else {
                return nil
            }
            return url
        }
        set {
            if let file = newValue {
                self = .file(file)
            } else {
                self = .none
            }
        }
    }
    
    public var stream: InputStream? {
        get {
            guard case .stream(let stream) = self else {
                return nil
            }
            return stream
        }
        set {
            if let stream = newValue {
                self = .stream(stream)
            } else {
                self = .none
            }
        }
    }
}

extension HTTPRequestBody {
    
    public var string: String? {
        get {
            switch self {
            case .data(let data):
                return String(bytes: data, encoding: .utf8)
            default:
                return nil
            }
        }
        set {
            if let str = newValue, let data = str.data(using: .utf8) {
                self = .data(data)
            } else {
                self = .none
            }
        }
    }
    
    public static func string(_ string: String) -> HTTPRequestBody {
        var body = HTTPRequestBody.none
        body.string = string
        return body
    }
    
    public var json: Any? {
        get {
            switch self {
            case .data(let data):
                return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            default:
                return nil
            }
        }
        set {
            if let obj = newValue, let data = try? JSONSerialization.data(withJSONObject: obj, options: []) {
                self = .data(data)
            } else {
                self = .none
            }
        }
    }
    
    public static func json(_ json: Any) -> HTTPRequestBody {
        var body = HTTPRequestBody.none
        body.json = json
        return body
    }
}
