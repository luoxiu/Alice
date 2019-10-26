import Foundation

public enum HTTPResponseBody {
    
    case none
    case data(Data)
    case file(URL)
    
    case custom(Any)
}

extension HTTPResponseBody {
    
    public var data: Data? {
        guard case .data(let data) = self else {
            return nil
        }
        return data
    }
    
    public var file: URL? {
        guard case .file(let file) = self else {
            return nil
        }
        return file
    }
    
    public var string: String? {
        switch self {
        case .data(let data):
            return String(bytes: data, encoding: .utf8)
        case .file(let url):
            return try? String(contentsOf: url)
        default:
            return nil
        }
    }
}
