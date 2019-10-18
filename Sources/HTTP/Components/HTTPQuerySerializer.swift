import Foundation

public struct HTTPQuerySerializer {
    
    public enum ArraySerializingStrategy {
        case bracket        // a[]=1&a[]=2
        case comma          // a=1,2
        case index          // a[0]=1&a[1]=2
        case `repeat`       // a=1&a=2
    }
    
    public enum BoolSerializingStrategy {
        case literal        // true & false
        case custom((Bool) -> String)
    }
    
    public enum DataSerializingStrategy {
        case base64
        case custom((Data) -> String)
    }
    
    public enum DateSerializingStrategy {
        case formatted(DateFormatter)
        case iso8601
        case millisecondsSince1970
        case secondsSince1970
        case custom((Date) -> String)
    }
    
    public enum NonConformingFloatSerializingStrategy {
        case convertToString(positiveInfinity: String, negativeInfinity: String, nan: String)
    }
    
    public var arraySerializingStrategy = ArraySerializingStrategy.repeat
    public var boolSerializingStrategy = BoolSerializingStrategy.literal
    public var dataSerializingStrategy = DataSerializingStrategy.base64
    public var dateSerializingStrategy = DateSerializingStrategy.iso8601
    public var nonConformingFloatSerializingStrategy = NonConformingFloatSerializingStrategy.convertToString(positiveInfinity: "-Infinity", negativeInfinity: "Infinity", nan: "Nan")
    
    public init() {
    }
    
    private typealias Parameter = (name: String, value: String)
    
    public func serialize(_ parameters: [String: Any]) -> String {
        var items: [Parameter] = []
        
        for kv in parameters.sorted(by: { $0.key < $1.key }) {
            items.append(contentsOf: self.serialize(kv.value, for: kv.key))
        }
        
        return items.map({ "\($0)=\($1)" }).joined(separator: "&")
    }
    
    public func serialize(_ parameters: [String: Any], into query: inout HTTPQuery) {
        var items: [Parameter] = []
        
        for kv in parameters.sorted(by: { $0.key < $1.key }) {
            items.append(contentsOf: self.serialize(kv.value, for: kv.key))
        }
        
        for item in items {
            query.add(item.value, for: item.name)
        }
    }
    
    private func serialize(_ value: Any, for name: String) -> [Parameter] {
        switch value {
        case let array as Array<Any>:
            let strs = array.map({ self.serializeNonArrayValue($0) })
            
            switch self.arraySerializingStrategy {
            case .bracket:
                return strs.map {
                    (name + "[]", $0)
                }
            case .comma:
                return [(name, strs.joined(separator: ","))]
            case .index:
                return strs.enumerated().map {
                    (name + "[\($0)]", $1)
                }
            case .repeat:
                return strs.map {
                    (name, $0)
                }
            }
        default:
            return [(name, self.serializeNonArrayValue(value))]
        }
    }
    
    private func serializeNonArrayValue(_ value: Any) -> String {
        switch value {
        case let str as String:
            return str
        case let bool as Bool:
            return self.serializeBool(bool)
        case let num as NSNumber:
            return self.serializeNumber(num)
        case let data as Data:
            return self.serializeData(data)
        case let date as Date:
            return self.serializeDate(date)
        default:
            return "\(value)"
        }
    }
    
    private func serializeBool(_ bool: Bool) -> String {
        switch self.boolSerializingStrategy {
        case .literal:
            return bool ? "true" : "false"
        case .custom(let fn):
            return fn(bool)
        }
    }
    
    private func serializeData(_ data: Data) -> String {
        switch self.dataSerializingStrategy {
        case .base64:
            return data.base64EncodedString()
        case .custom(let fn):
            return fn(data)
        }
    }
    
    private func serializeDate(_ date: Date) -> String {
        switch self.dateSerializingStrategy {
        case .formatted(let fmt):
            return fmt.string(from: date)
        case .iso8601:
            return _iso8601DateFormatter.string(from: date)
        case .millisecondsSince1970:
            return self.serializeFloat(date.timeIntervalSince1970 * 1000)
        case .secondsSince1970:
            return self.serializeFloat(date.timeIntervalSince1970)
        case .custom(let fn):
            return fn(date)
        }
    }
    
    private func serializeFloat<T: FloatingPoint & LosslessStringConvertible>(_ num: T) -> String {
        if num.isNaN || num.isInfinite {
            switch self.nonConformingFloatSerializingStrategy {
            case .convertToString(let positiveInfinity, let negativeInfinity, let nan):
                if num.isNaN {
                    return nan
                }
                return num > 0 ? positiveInfinity : negativeInfinity
            }
        }
        
        var str = num.description
        if str.hasSuffix(".0") {
            str.removeLast(2)
        }
        return str
    }
    
    private func serializeNumber(_ num: NSNumber) -> String {
        if CFNumberIsFloatType(num) {
            return self.serializeFloat(num.doubleValue)
        } else if CFGetTypeID(num) == CFBooleanGetTypeID() {
            return self.serializeBool(num.boolValue)
        } else {
            return num.stringValue
        }
    }
}

private let _iso8601DateFormatter = ISO8601DateFormatter()
