import simd

public struct Observation: Equatable {
    public typealias Scalar = Double
    public typealias Vector = SIMD3<Double>

    public var xyz: Vector
    public var measurement: Scalar
}

extension Observation {
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    public func sample(stdDeviation: Double) -> Vector {
        let uniform = DefaultUniformRandom()
        let gaussian = DefaultGaussianRandom()
        return self.sample(
            stdDeviation: stdDeviation,
            uniformRandom: uniform,
            gaussianRandom: gaussian
        )
    }
    
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    internal func sample<U, G>(
        stdDeviation: Double,
        uniformRandom: U,
        gaussianRandom: G
    ) -> Vector
        where U: UniformRandom, U.Value == Double, G: GaussianRandom, G.Value == Double
    {
        var uniformRandom = uniformRandom
        var gaussianRandom = gaussianRandom
        
        let xyz = self.xyz
        let radius = gaussianRandom.random(
            mean: self.measurement,
            stdDeviation: stdDeviation
        )
        
        let v = uniformRandom.random()
        
        let theta = uniformRandom.random(in: 0.0..<(2.0 * .pi))
        let phi = acos((2.0 * v) - 1.0)

        let x = xyz.x + (radius * sin(phi) * cos(theta))
        let y = xyz.y + (radius * sin(phi) * sin(theta))
        let z = xyz.z + (radius * cos(phi))
        
        return [x, y, z]
    }
}
