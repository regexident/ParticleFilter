import XCTest

@testable import ParticleFilter

class CollectionTests: XCTestCase {
    // Corners of a unit cube:
    static let particles: [Particle] = [
        Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
        Particle(location: [0.0, 0.0, 1.0], weight: 2.0),
        Particle(location: [0.0, 1.0, 0.0], weight: 3.0),
        Particle(location: [0.0, 1.0, 1.0], weight: 4.0),
        Particle(location: [1.0, 0.0, 0.0], weight: 5.0),
        Particle(location: [1.0, 0.0, 1.0], weight: 6.0),
        Particle(location: [1.0, 1.0, 0.0], weight: 7.0),
        Particle(location: [1.0, 1.0, 1.0], weight: 8.0),
    ]
    
    func test__mean() {
        let particles = type(of: self).particles
        let mean = particles.mean()
        
        // Center of a unit cube:
        let expected: Particle.Location = [0.5, 0.5, 0.5]
        
        XCTAssertEqual(mean, expected, accuracy: 0.0001)
    }
    
    func test__mean_weighted() {
        let particles = type(of: self).particles
        let mean = particles.mean(weighted: true)
        
        // Center of a unit cube:
        let expected: Particle.Location = [0.7222, 0.6111, 0.5555]
        
        XCTAssertEqual(mean, expected, accuracy: 0.0001)
    }
    
    func test__mean__benchmark() {
        let particleCount = 1000
        
        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Double(i)
            return Particle(
                location: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: 1.0
            )
        }

        measure {
            let _ = particles.mean()
        }
    }

    func test__variance() {
        let particles = type(of: self).particles
        let mean = particles.mean()
        let variance = particles.variance(around: mean)
        
        XCTAssertEqual(variance, [0.25, 0.25, 0.25], accuracy: 0.01)
    }
    
    func test__variance_weighted() {
        let particles = type(of: self).particles
        let mean = particles.mean(weighted: true)
        let variance = particles.variance(around: mean, weighted: true)
        
        XCTAssertEqual(variance, [0.200, 0.237, 0.250], accuracy: 0.01)
    }

    func test__variance__benchmark() {
        let particleCount = 1000
        
        let mean: Particle.Location = [0.0, 0.0, 0.0]
        
        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Particle.Scalar(i)
            return Particle(
                location: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: 1.0
            )
        }

        measure {
            let _ = particles.variance(around: mean)
        }
    }
}
