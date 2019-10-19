import Foundation

public struct HTTPQueryItem {
    
    public var name: String
    public var value: String?
}

public struct HTTPQuery {
    
    private var storage: [HTTPQueryItem]
    
    public init() {
        self.storage = []
    }
    
    public init(queryItems: [URLQueryItem]) {
        self.storage = queryItems.map { HTTPQueryItem(name: $0.name, value: $0.value) }
    }
    
    public init(string: String) {
        let raw = HTTPQuery.escapeSafely(string)
        if let items = URLComponents(string: "?" + raw)?.queryItems {
            self.init(queryItems: items)
            return
        }
        self.init()
    }
    
    public mutating func add(_ value: String?, for name: String) {
        self.storage.append(HTTPQueryItem(name: name, value: value))
    }
    
    public mutating func set(_ value: String?, for name: String) {
        let item = HTTPQueryItem(name: name, value: value)
        
        if let index = self.storage.firstIndex(where: { $0.name == name }) {
            self.storage.removeAll(where: { $0.name == name })
            self.storage.insert(item, at: index)
        } else {
            self.storage.append(item)
        }
    }
    
    public mutating func remove(_ name: String) {
        self.storage.removeAll(where: { $0.name == name })
    }
    
    public mutating func removeAll() {
        self.storage.removeAll()
    }
    
    public func value(for name: String) -> String? {
        return self.storage.first(where: { $0.name == name })?.value
    }
    
    public func allValues(for name: String) -> [String] {
        return self.storage.compactMap { $0.name == name ? $0.value : nil }
    }
    
    public func contains(_ name: String) -> Bool {
        return self.storage.contains(where: { $0.name == name })
    }
    
    private static func escapeSafely(_ str: String) -> String {
        let queryAllowed = CharacterSet.urlQueryAllowed
        if !str.characterSet.isSubset(of: queryAllowed), let encoded = str.addingPercentEncoding(withAllowedCharacters: queryAllowed) {
            return encoded
        }
        return str
    }
    
    public func toQueryString() -> String {
        return self.storage
            .map {
                var str = HTTPQuery.escapeSafely($0.name)
                if let value = $0.value {
                    str += "=\(HTTPQuery.escapeSafely(value))"
                }
                return str
            }
            .joined(separator: "&")
    }
    
    public func toQueryItems() -> [URLQueryItem] {
        return self.storage.map {
            URLQueryItem(name: $0.name, value: $0.value)
        }
    }
    
    public func toHTTPQueryItems() -> [HTTPQueryItem] {
        return self.storage
    }
}
