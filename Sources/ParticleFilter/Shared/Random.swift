import Darwin

internal protocol UniformRandom {
    associatedtype Value: FloatingPoint
    
    /// Returns random value of uniform distribution within 0 ..< 1.0
    mutating func random() -> Value
    
    /// Returns random value of uniform distribution within `range`
    mutating func random(in range: Range<Value>) -> Value
}

extension UniformRandom {
    mutating func random(in range: Range<Value>) -> Value {
        let a = range.upperBound - range.lowerBound
        let b = range.lowerBound
        let x = self.random()
        return (a * x) + b
    }
}

internal protocol GaussianRandom {
    associatedtype Value: FloatingPoint
    
    // Returns random value of standard gaussian distribution with mean `0.0` and std-deviation `1.0`
    mutating func random() -> Value
    
    // Returns random value of standard gaussian distribution with mean `mean` and std-deviation `stdDeviation`
    mutating func random(mean: Value, stdDeviation: Value) -> Value
}

internal struct BoxMullerTransform {
    internal func transform(a: Double, b: Double, c: Double) -> Double {
        assert(a >= 0.0 && a < 1.0)
        assert(b >= 0.0 && b <= 1.0)
        assert(c >= 0.0 && c <= 1.0)
        
        let d = abs(-2.0 * log(a))
        let e = 2.0 * .pi * b
        
        let f: Double
        if c < 0.5 {
            f = sqrt(d) * sin(e)
        } else {
            f = sqrt(d) * cos(e)
        }
        
        return min(1.0, max(-1.0, f))
    }
}

internal struct DefaultUniformRandom: UniformRandom {
    internal typealias Value = Double

    internal mutating func random() -> Value {
        return Double.random(in: 0.0..<1.0)
    }
    
    internal mutating func random(in range: Range<Value>) -> Value {
        return Double.random(in: range)
    }    
}

internal struct DefaultGaussianRandom: GaussianRandom {
    internal typealias Value = Double
    
    private var uniform: DefaultUniformRandom = .init()
    
    internal mutating func random() -> Value {
        let boxMuller = BoxMullerTransform()
        
        let a = self.uniform.random()
        let b = self.uniform.random()
        let c = self.uniform.random()

        return boxMuller.transform(a: a, b: b, c: c)
    }
    
    internal mutating func random(mean: Value, stdDeviation: Value) -> Value {
        return mean + (self.random() * stdDeviation)
    }
}
