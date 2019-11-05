import Darwin

import Surge

public struct Particle: Equatable {
    public typealias State = Vector<Double>
    public typealias Weight = Double

    public var state: State
    public var weight: Weight

    public init(state: State, weight: Weight = 0.0) {
        self.state = state
        self.weight = weight
    }
    
    public func with(state: State) -> Particle {
        return Particle(state: state, weight: weight)
    }

    public func with(weight: Weight) -> Particle {
        return Particle(state: self.state, weight: weight)
    }
}
