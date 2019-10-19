import Foundation

public struct BagToken: Hashable {

    fileprivate let val: UInt64
}

public struct Bag<Element> {
    
    private typealias Entry = (key: BagToken, val: Element)
    
    private var _nextToken = BagToken(val: 0)
    private var _entry0: Entry?
    private var _entry1: Entry?
    private var _entryList: [Entry]?
    
    public init() { }
    
    @discardableResult
    public mutating func append(_ element: Element) -> BagToken {
        let token = self._nextToken
        self._nextToken = BagToken(val: token.val + 1)

        let entry = (key: token, val: element)
        
        switch token.val {
        case 0:     self._entry0 = entry
        case 1:     self._entry1 = entry
        case 2:     self._entryList = [entry]
        default:    self._entryList!.append(entry)
        }
        
        return token
    }
    
    public func value(for token: BagToken) -> Element? {
        switch token.val {
        case 0:     return self._entry0?.val
        case 1:     return self._entry1?.val
        default:    return self._entryList?.first(where: { $0.key == token })?.val
        }
    }
    
    @discardableResult
    public mutating func removeValue(for token: BagToken) -> Element? {
        switch token.val {
        case 0:     return self._entry0.clear()?.val
        case 1:     return self._entry1.clear()?.val
        default:
            if let idx = self._entryList?.firstIndex(where: { $0.key == token }) {
                return self._entryList?.remove(at: idx).val
            }
        }
        
        return nil
    }
    
    public mutating func removeAll() {
        self._entry0 = nil
        self._entry1 = nil
        self._entryList?.removeAll()
    }
    
    public var count: Int {
        let x = (self._entry0 == nil ? 0 : 1)
        let y = (self._entry1 == nil ? 0 : 1)
        let z = (self._entryList?.count ?? 0)
        
        return x + y + z
    }
}

extension Bag {
    
    static func empty() -> Bag {
        return Bag()
    }
}

extension Bag: Sequence {
    
    public func makeIterator() -> AnyIterator<Element> {
        var entry0 = self._entry0
        var entry1 = self._entry1
        var iterator = self._entryList?.makeIterator()
        
        return AnyIterator<Element> {
            if let val = entry0?.val {
                entry0 = nil
                return val
            }
            if let val = entry1?.val {
                entry1 = nil
                return val
            }
            return iterator?.next()?.val
        }
    }
}
