import Foundation

#if canImport(Darwin)
@usableFromInline
final class SpinLock: NSLocking {
    
    @usableFromInline
    var _lock = os_unfair_lock()
    
    @inlinable
    init() { }
    
    @inlinable
    func lock() {
        os_unfair_lock_lock(&self._lock)
    }
    
    @inlinable
    func unlock() {
        os_unfair_lock_unlock(&self._lock)
    }
}
#endif

public final class Lock: NSLocking {
    
    @usableFromInline
    let wrapped: NSLocking
    
    @inlinable
    public init() {
        #if canImport(Darwin)
        self.wrapped = SpinLock()
        #else
        self.wrapped = NSLock()
        #endif
    }
    
    @inlinable
    public func lock() {
        self.wrapped.lock()
    }
    
    @inlinable
    public func unlock() {
        self.wrapped.unlock()
    }
}
