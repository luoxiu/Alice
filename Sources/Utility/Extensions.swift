import Foundation

extension NSLocking {
    
    @inlinable
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
    
    @inlinable
    public func withLockVoid(_ body: () throws -> Void) rethrows {
        self.lock()
        defer { self.unlock() }
        try body()
    }
}

extension DispatchQueue {
    
    @inlinable
    public static func `is`(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<Void>()
        queue.setSpecific(key: key, value: ())
        defer {
            queue.setSpecific(key: key, value: nil)
        }
        return DispatchQueue.getSpecific(key: key) != nil
    }
}

extension Result {
    
    @inlinable
    public var success: Success? {
        if case .success(let v) = self { return v }
        return nil
    }
    
    @inlinable
    public var failure: Failure? {
        if case .failure(let e) = self { return e }
        return nil
    }
}
