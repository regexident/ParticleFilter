import simd

public struct Particle: Equatable {
    public typealias Scalar = Double
    public typealias Vector = SIMD3<Double>
    
    public var xyz: Vector
    public var weight: Scalar
    
    public func with(xyz: Vector) -> Particle {
        return Particle(xyz: xyz, weight: self.weight)
    }
    
    public func with(weight: Scalar) -> Particle {
        return Particle(xyz: self.xyz, weight: weight)
    }
}
