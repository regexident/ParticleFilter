import XCTest

@testable import ParticleFilter

extension Double: NearEquatable {
    typealias Difference = Double
    
    func isNearEqual(to other: Double, accuracy: Difference) -> Bool {
        return abs(self - other) <= accuracy
    }
}

extension Float: NearEquatable {
    typealias Difference = Float
    
    func isNearEqual(to other: Float, accuracy: Difference) -> Bool {
        return abs(self - other) <= accuracy
    }
}

extension Double3: NearEquatable {
    typealias Difference = Double
    
    func isNearEqual(to other: Double3, accuracy: Difference) -> Bool {
        let distance = self.distance(to: other)
        return distance.isNearEqual(to: 0.0, accuracy: accuracy)
    }
}

extension Particle: NearEquatable {
    typealias Difference = Double
    
    func isNearEqual(to other: Particle, accuracy: Difference) -> Bool {
        guard self.xyz.isNearEqual(to: other.xyz, accuracy: accuracy) else {
            return false
        }
        guard self.weight.isNearEqual(to: other.weight, accuracy: accuracy) else {
            return false
        }
        return true
    }
}
