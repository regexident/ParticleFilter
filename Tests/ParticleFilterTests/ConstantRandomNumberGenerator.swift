import Foundation

//struct ConstantRandomNumberGenerator: RandomNumberGenerator {
//    let constant: UInt64
//
//    init(constant: UInt64) {
//        self.constant = constant
//    }
//
//    func next() -> UInt64 {
//        print("!")
//        return self.constant
//    }
//}

struct IncrementingRandomNumberGenerator: RandomNumberGenerator {
    var value: UInt64
    
    init(from value: UInt64 = 0) {
        self.value = value
    }
    
    mutating func next() -> UInt64 {
        defer {
            self.value += 1
        }
        return self.value
    }
    
    mutating func next<T>(upperBound: T) -> T where T : FixedWidthInteger, T : UnsignedInteger {
        return self.next() % upperBound
    }
}
