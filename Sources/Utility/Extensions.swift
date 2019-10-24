import Foundation

extension NSLocking {
    
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
    
    public func withLockVoid(_ body: () throws -> Void) rethrows {
        self.lock()
        defer { self.unlock() }
        try body()
    }
}

extension DispatchQueue {
    
    public static func `is`(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<Void>()
        queue.setSpecific(key: key, value: ())
        defer {
            queue.setSpecific(key: key, value: nil)
        }
        return DispatchQueue.getSpecific(key: key) != nil
    }
    
    
    public func safeSync<T>(_ body: () throws -> T) rethrows -> T {
        if DispatchQueue.is(self) {
            return try body()
        } else {
            return try self.sync(execute: body)
        }
    }
}

extension Result {
    
    public var success: Success? {
        if case .success(let v) = self { return v }
        return nil
    }
    
    public var failure: Failure? {
        if case .failure(let e) = self { return e }
        return nil
    }
}

extension Optional {
    
    public mutating func clear() -> Wrapped? {
        defer { self = nil }
        return self
    }
    
    public mutating func setWhenNone(_ new: Wrapped) {
        if self == nil {
            self = new
        }
    }
}

extension String {
    
    public var characterSet: CharacterSet {
        return CharacterSet(charactersIn: self)
    }
    
    public var ns: NSString {
        return self as NSString
    }
}

