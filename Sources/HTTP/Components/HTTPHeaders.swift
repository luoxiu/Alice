import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct HTTPHeader {
    
    public var name: HTTPHeaderName
    public var value: String
    
    public init(name: HTTPHeaderName, value: String) {
        self.name = name
        self.value = value
    }
    
    public var headerValue: HTTPHeaderValue {
        return .init(rawString: self.value)
    }
}

public struct HTTPHeaders {
    
    private var storage: [HTTPHeader]

    public init() {
        self.storage = []
    }
    
    public init(dict: [String: String]) {
        self.storage = dict.map {
            HTTPHeader(name: HTTPHeaderName($0.key), value: $0.value)
        }
    }
    
    public subscript(name: HTTPHeaderName) -> String? {
        get {
            return self.value(for: name)
        }
        set {
            if let value = newValue {
                self.set(value, for: name)
            } else {
                self.remove(name)
            }
        }
    }
    
    public var headers: [HTTPHeader] {
        return self.storage
    }
    
    public mutating func add(_ value: String, for name: HTTPHeaderName) {
        if let index = self.storage.firstIndex(where: { $0.name == name }) {
            self.storage[index].value.append("," + value)
        } else {
            self.storage.append(HTTPHeader(name: name, value: value))
        }
    }
    
    public mutating func set(_ value: String, for name: HTTPHeaderName) {
        if let index = self.storage.firstIndex(where: { $0.name == name }) {
            self.storage[index].value = value
        } else {
            self.storage.append(HTTPHeader(name: name, value: value))
        }
    }
    
    public mutating func remove(_ name: HTTPHeaderName) {
        self.storage.removeAll(where: { $0.name == name })
    }
    
    public mutating func removeAll() {
        self.storage.removeAll()
    }
    
    public func value(for name: HTTPHeaderName) -> String? {
        return self.storage.first(where: { $0.name == name })?.value
    }
    
    public func contains(_ name: HTTPHeaderName) -> Bool {
        return self.value(for: name) != nil
    }
    
    public func httpValue(for name: HTTPHeaderName) -> HTTPHeaderValue? {
        return self.storage.first(where: { $0.name == name })?.headerValue
    }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, String)...) {
        self.storage = []
        self.storage.reserveCapacity(elements.count)
        for kv in elements {
            self.add(kv.0, for: HTTPHeaderName(kv.1))
        }
    }
}

extension HTTPHeaders: CustomStringConvertible {
    
    public var description: String {
        return self.storage
            .map {
                ($0.name.rawValue.lowercased(), $0.value)
            }
            .description
    }
}

extension HTTPHeaders {
    
    public func toDictionary() -> [String: String] {
        var dict: [String: String] = .init(minimumCapacity: self.storage.count)
        for header in self.storage {
            dict[header.name.rawValue] = header.value
        }
        return dict
    }
}

extension HTTPHeaders {
    
    static func of(_ request: URLRequest) -> HTTPHeaders {
        guard let headers = request.allHTTPHeaderFields else {
            return HTTPHeaders()
        }
        return HTTPHeaders(dict: headers)
    }
    
    static func of(_ response: HTTPURLResponse) -> HTTPHeaders {
        guard let headers = response.allHeaderFields as? [String: String] else {
            return HTTPHeaders()
        }
        return HTTPHeaders(dict: headers)
    }
}
