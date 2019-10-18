import Foundation

public struct HTTPProgress {
    
    public let totalUnitCount: Int64
    public let completedUnitCount: Int64
    
    public init(totalUnitCount: Int64, completedUnitCount: Int64) {
        self.totalUnitCount = totalUnitCount
        self.completedUnitCount = completedUnitCount
    }
    
    public var fractionCompleted: Double {
        if totalUnitCount < 0 || completedUnitCount < 0 {
            return 0
        }
        
        if totalUnitCount == 0 {
            return 1
        }
        
        let fraction = Double(completedUnitCount) / Double(totalUnitCount)
        return min(fraction, 1)
    }
}
