import Foundation

extension Thenable {
    
    @inlinable
    public func with(_ body: @escaping (inout Success) -> Void) -> Future<Success, Failure> {
        return self.map {
            var m = $0
            body(&m)
            return m
        }
    }
}
