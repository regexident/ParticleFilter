import Darwin

internal struct BoxMullerTransform {
    internal func transform(_ a: Float, _ b: Float, _ c: Float) -> Float {
        assert(a >= 0.0 && a < 1.0)
        assert(b >= 0.0 && b <= 1.0)
        assert(c >= 0.0 && c <= 1.0)
        
        let d = abs(-2.0 * log(a))
        let e = 2.0 * .pi * b
        
        let f: Float
        if c < 0.5 {
            f = sqrt(d) * sin(e)
        } else {
            f = sqrt(d) * cos(e)
        }
        
        return min(1.0, max(-1.0, f))
    }
    
    internal func transform(_ a: Double, _ b: Double, _ c: Double) -> Double {
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

extension Float {
    static func normalRandom() -> Self {
        var generator = SystemRandomNumberGenerator()
        return self.normalRandom(using: &generator)
    }
    
    static func normalRandom<T>(using generator: inout T) -> Self where T : RandomNumberGenerator {
        let boxMuller = BoxMullerTransform()
        
        let a = self.random(in: 0.0...1.0, using: &generator)
        let b = self.random(in: 0.0...1.0, using: &generator)
        let c = self.random(in: 0.0...1.0, using: &generator)
        
        return boxMuller.transform(a, b, c)
    }
    
    static func normalRandom(mean: Self, stdDeviation: Self) -> Self {
        var generator = SystemRandomNumberGenerator()
        return self.normalRandom(mean: mean, stdDeviation: stdDeviation, using: &generator)
    }
    
    static func normalRandom<T>(mean: Self, stdDeviation: Self, using generator: inout T) -> Self where T : RandomNumberGenerator {
        return mean + (self.normalRandom(using: &generator) * stdDeviation)
    }
}

extension Double {
    static func normalRandom() -> Self {
        var generator = SystemRandomNumberGenerator()
        return self.normalRandom(using: &generator)
    }
    
    static func normalRandom<T>(using generator: inout T) -> Self where T : RandomNumberGenerator {
        let boxMuller = BoxMullerTransform()
        
        let a = self.random(in: 0.0...1.0, using: &generator)
        let b = self.random(in: 0.0...1.0, using: &generator)
        let c = self.random(in: 0.0...1.0, using: &generator)
        
        return boxMuller.transform(a, b, c)
    }
    
    static func normalRandom(mean: Self, stdDeviation: Self) -> Self {
        var generator = SystemRandomNumberGenerator()
        return self.normalRandom(mean: mean, stdDeviation: stdDeviation, using: &generator)
    }
    
    static func normalRandom<T>(mean: Self, stdDeviation: Self, using generator: inout T) -> Self where T : RandomNumberGenerator {
        return mean + (self.normalRandom(using: &generator) * stdDeviation)
    }
}
