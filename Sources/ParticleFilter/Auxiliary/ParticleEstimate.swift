import Darwin

import Surge

public struct ParticleEstimate: Equatable {
    public typealias Weight = Double
    public typealias State = Vector<Double>

    public private(set) lazy var mean: State = self.mean()
    public private(set) lazy var variance: State = self.variance(around: self.mean)

    public let count: Int
    public let states: [State]
    public let weights: [Weight]

    init<S>(particles: S) where S: Sequence, S.Element == Particle {
        var weights: [Weight] = []
        var states: [State] = []

        for particle in particles {
            states.append(particle.state)
            weights.append(particle.weight)
        }

        self.init(states: states, weights: weights)
    }

    public init(states: [State], weights: [Weight]? = nil) {
        assert(states.count > 0)
        assert(states.count == (weights?.count ?? states.count))
        assert(
            Set(states.map { $0.count }).count == 1,
            "Expected state dimensions to be uniform"
        )

        let count = states.count // same as `weights.count`
        let weights = weights ?? Array(repeating: 1.0 / Double(count), count: count)

        self.states = states
        self.weights = weights
        self.count = count
    }

    /// Calculates the mean of particle cloud:
    ///
    /// - Parameters:
    ///   - weighted: Whether to consider individual particle weights.
    internal func mean(weighted: Bool = false) -> Particle.State {
        assert(!self.isEmpty)

        // https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Mathematical_definition

        guard let firstParticle = self.first else {
            fatalError("An empty collection does not have a mean")
        }

        var totalWeight: Double = 0.0
        let uniformWeight = 1.0 / Double(self.count)
        let dimensions = firstParticle.state.dimensions
        var mean = Vector(dimensions: dimensions, repeatedValue: 0.0)

        for particle in self {
            let weight = weighted ? particle.weight : uniformWeight

            mean += weight * particle.state
            totalWeight += weight
        }

        return mean / totalWeight
    }

    /// Calculates the variance from the `mean`:
    ///
    /// - Parameters
    ///   - mean: The mean to calculate the variance from.
    internal func variance(around mean: Particle.State, weighted: Bool = false) -> Particle.State {
        assert(!self.isEmpty)

        // https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Weighted_sample_variance

        var totalWeight: Double = 0.0
        let uniformWeight = 1.0 / Double(self.count)
        let dimensions = mean.dimensions
        var variance = Vector(dimensions: dimensions, repeatedValue: 0.0)

        for particle in self {
            let weight = weighted ? particle.weight : uniformWeight
            let delta = particle.state - mean

            variance += weight * (delta .* delta)
            totalWeight += weight
        }

        return variance / totalWeight
    }
}

extension ParticleEstimate: Collection {
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
        let state = self.states[position] // Vector(self.states.map { $0[position] })
        let weight = self.weights[position]
        return Particle(state: state, weight: weight)
    }
}
