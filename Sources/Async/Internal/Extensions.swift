import Foundation

extension NSLocking {
    
    @inlinable
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
    
    @inlinable
    func withLockVoid(_ body: () throws -> Void) rethrows {
        self.lock()
        defer { self.unlock() }
        try body()
    }
}

extension DispatchQueue {
    
    @inlinable
    static func `is`(_ queue: DispatchQueue) -> Bool {
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
    var value: Success? {
        if case .success(let v) = self { return v }
        return nil
    }
    
    @inlinable
    var error: Failure? {
        if case .failure(let e) = self { return e }
        return nil
    }
}
