import Darwin

import Surge

extension Vector where Scalar == Float {
    public func magnitude() -> Scalar {
        return sqrt(self.magnitudeSquared())
    }
    
    public func magnitudeSquared() -> Scalar {
        return Surge.dot(self, self)
    }
    
    public func distance(to other: Vector<Scalar>) -> Scalar {
        return Surge.dist(self, other)
    }
    
    public func distanceSquared(to other: Vector<Scalar>) -> Scalar {
        return Surge.distSq(self, other)
    }
}

extension Vector where Scalar == Double {
    public func magnitude() -> Scalar {
        return sqrt(self.magnitudeSquared())
    }
    
    public func magnitudeSquared() -> Scalar {
        return Surge.dot(self, self)
    }
    
    public func distance(to other: Vector<Scalar>) -> Scalar {
        return Surge.dist(self, other)
    }
    
    public func distanceSquared(to other: Vector<Scalar>) -> Scalar {
        return Surge.distSq(self, other)
    }
}

extension Vector where Scalar == Float {
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    public func sample(
        radius: Scalar,
        stdDeviation: Scalar
    ) -> Vector<Scalar> {
        var generator = SystemRandomNumberGenerator()
        return self.sample(
            radius: radius,
            stdDeviation: stdDeviation,
            using: &generator
        )
    }
    
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    public func sample<T>(
        radius: Scalar,
        stdDeviation: Scalar,
        using generator: inout T
    ) -> Vector<Scalar>
        where T: RandomNumberGenerator
    {
        var generator = generator
        
        let dimensions = self.dimensions
        
        // To generate uniformly distributed random points on the unit (n − 1)-sphere
        // (that is, the surface of the unit n-ball), Marsaglia (1972) gives the following algorithm:
        // https://en.wikipedia.org/wiki/N-sphere#Uniformly_at_random_on_the_(n_%E2%88%92_1)-sphere
        
        // Generate an n-dimensional vector `x` of normal deviates (it suffices to use N(0, 1),
        // although in fact the choice of the variance is arbitrary), x = (x1, x2,... xn):
        let vector = Vector((0..<dimensions).map { _ in
            Scalar.randomNormal(mu: 0.0, sigma: 1.0, using: &generator)
        })
        
        // Now calculate the "radius" `r` of this point:
        let radius = vector.magnitude()
        
        // The vector `x / r` is uniformly distributed over the surface of the unit n-sphere:
        let sample = vector / radius
        
        // Create normal-distributed noise vector with given `stdDeviation` around the origin:
        let noise = Vector((0..<dimensions).map { _ in
            Scalar.randomNormal(mu: 0.0, sigma: 1.0, using: &generator)
        })
        
        // Scale up n-sphere unit vector and add noise:
        return (sample * radius) + noise
    }
}

extension Vector where Scalar == Double {
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    public func sampleSphere(
        radius: Scalar,
        stdDeviation: Scalar
    ) -> Vector<Scalar> {
        var generator = SystemRandomNumberGenerator()
        return self.sampleSphere(
            radius: radius,
            stdDeviation: stdDeviation,
            using: &generator
        )
    }
    
    /// Returns random sample on sphere with
    /// - radius: `observation.measurement`
    /// - center: `observation.xyz`
    /// and a guassian distribution on radius
    /// with std-deviation of `stdDeviation`.
    public func sampleSphere<T>(
        radius: Scalar,
        stdDeviation: Scalar,
        using generator: inout T
    ) -> Vector<Scalar>
        where T: RandomNumberGenerator
    {
        var generator = generator
        
        let dimensions = self.dimensions
        
        // To generate uniformly distributed random points on the unit (n − 1)-sphere
        // (that is, the surface of the unit n-ball), Marsaglia (1972) gives the following algorithm:
        // https://en.wikipedia.org/wiki/N-sphere#Uniformly_at_random_on_the_(n_%E2%88%92_1)-sphere
        
        // Generate an n-dimensional vector `x` of normal deviates (it suffices to use N(0, 1),
        // although in fact the choice of the variance is arbitrary), x = (x1, x2,... xn):
        let vector = Vector((0..<dimensions).map { _ in
            Scalar.randomNormal(mu: 0.0, sigma: 1.0, using: &generator)
        })
        
        // Now calculate the "radius" `r` of this point:
        let radius = vector.magnitude()
        
        // The vector `x / r` is uniformly distributed over the surface of the unit n-sphere:
        let sample = vector / radius
        
        // Create normal-distributed noise vector with given `stdDeviation` around the origin:
        let noise = Vector((0..<dimensions).map { _ in
            Scalar.randomNormal(mu: 0.0, sigma: stdDeviation, using: &generator)
        })
        
        // Scale up n-sphere unit vector and add noise:
        return (sample * radius) + noise
    }
}
