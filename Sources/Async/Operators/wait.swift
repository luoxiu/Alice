import Foundation
import Utility

extension Thenable {
    
    @inlinable
    public func wait() -> Success? {
        let sema = DispatchSemaphore(value: 0)
        self.whenComplete { _ in
            sema.signal()
        }
        sema.wait()
        
        return self.inspectWithoutLock()!.success
    }
    
    @inlinable
    public func waitError() -> Failure? {
        let sema = DispatchSemaphore(value: 0)
        self.whenComplete { _ in
            sema.signal()
        }
        sema.wait()
        
        return self.inspectWithoutLock()!.failure
    }
}
