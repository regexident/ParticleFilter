import Darwin

import Surge

public struct Particle: Equatable {
    public typealias Scalar = Double
    public typealias Location = Vector<Scalar>

    public var location: Location
    public var weight: Scalar

    public init(location: Location, weight: Scalar = 0.0) {
        self.location = location
        self.weight = weight
    }
    
    public func with(location: Location) -> Particle {
        return Particle(location: location, weight: weight)
    }

    public func with(weight: Scalar) -> Particle {
        return Particle(location: self.location, weight: weight)
    }
}
