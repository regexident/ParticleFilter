import Darwin

import Surge

public struct ParticleSet: Equatable {
    public typealias Scalar = Double
    public typealias Location = Vector<Scalar>

    public let count: Int
    public private(set) var locations: [[Scalar]]
    public private(set) var weights: [Scalar]

    init<S>(particles: S) where S: Sequence, S.Element == Particle {
        var count = 0
        var weights: [Scalar] = []
        var locations: [[Scalar]] = []
        for particle in particles {
            count += 1
            for (index, dimension) in particle.location.enumerated() {
                locations[index].append(dimension)
            }
            weights.append(particle.weight)
        }
        self.count = count
        self.locations = locations
        self.weights = weights
    }

    public init(locations: [[Scalar]], weights: [Scalar]) {
        assert(locations.count == weights.count)
        assert(Set(locations.map { $0.count }).count == 1)

        let count = locations.count // same as `weights.count`

        self.locations = locations
        self.weights = weights
        self.count = count
    }
}

extension ParticleSet: Collection {
    public typealias Element = Particle
    public typealias Index = Int

    public var startIndex: Self.Index {
        return 0
    }

    public var endIndex: Self.Index {
        return self.count
    }

    public func index(after index: Int) -> Int {
        return index + 1
    }

    public subscript(position: Int) -> Particle {
        let location = Vector(self.locations.map { $0[position] })
        let weight = self.weights[position]
        return Particle(location: location, weight: weight)
    }
}
