import Foundation

public struct Benchmark {
    static func with<T>(closure: () -> T) -> T {
        let start: UInt64 = mach_absolute_time()
        let result = closure()
        let end: UInt64 = mach_absolute_time()
        
        print("Time: \(Double(end - start) / Double(NSEC_PER_SEC))")
        
        return result
    }
}
