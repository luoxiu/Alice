import Foundation

public enum HTTPResponseBody {
    
    case none
    case data(Data)
    case file(URL)
}

extension HTTPResponseBody {
    
    public var data: Data? {
        get {
            switch self {
            case .data(let data):   return data
            case .file(let url):    return try? Data(contentsOf: url)
            default:                return nil
            }
        }
        set {
            if let data = newValue {
                self = .data(data)
                return
            }
            self = .none
        }
    }
    
    public var file: URL? {
        get {
            switch self {
            case .file(let url):    return url
            default:                return nil
            }
        }
        set {
            if let url = newValue {
                self = .file(url)
                return
            }
            self = .none
        }
    }
    
    public var string: String? {
        get {
            switch self {
            case .data(let data):
                return String(bytes: data, encoding: .utf8)
            case .file(let url):
                return try? String(contentsOf: url)
            case .none:
                return nil
            }
        }
        set {
            if let string = newValue, let data = string.data(using: .utf8) {
                self = .data(data)
                return
            }
            self = .none
        }
    }
    
    public var json: Any? {
        get {
            switch self {
            case .data(let data):
                return try? JSONSerialization.jsonObject(with: data, options: [])
            case .file(let url):
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONSerialization.jsonObject(with: data, options: [])
            case .none:
                return nil
            }
        }
        set {
            if let json = newValue, let data = try? JSONSerialization.data(withJSONObject: json, options: []) {
                self = .data(data)
                return
            }
            self = .none
        }
    }
}
