import Foundation

extension Future {
    
    // Alias for map
    @inlinable
    public func `return`<U>(_ body: @escaping (Success) -> U) -> Future<U, Failure> {
        return self.map(body)
    }
}
