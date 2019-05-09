import XCTest

@testable import ParticleFilter

class CPUParticleFilterTests: XCTestCase {
    let particleCount: Int = 10000

    func test__predict__staticMotion_zeroControl() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
        ]
        let model = MotionModel(stdDeviation: 0.0)
        let control: Particle.Vector = [0.0, 0.0, 0.0]

        let predicted = particleFilter.predict(
            particles: particles,
            control: control,
            model: model
        )

        let expected = particles

        XCTAssertEqual(predicted, expected)
    }

    func test__predict__staticMotion_nonZeroControl() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
        ]
        let model = MotionModel(stdDeviation: 0.0)
        let control: Particle.Vector = [0.1, 0.2, 0.3]

        let predicted = particleFilter.predict(
            particles: particles,
            control: control,
            model: model
        )

        let expected = [
            Particle(xyz: [0.1, 0.2, 0.3], weight: 1.0),
        ]

        XCTAssertEqual(predicted, expected)
    }

    func test__predict__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                xyz: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let model = MotionModel(stdDeviation: 1.0)
        let control: Particle.Vector = [0.1, 0.2, 0.3]

        measure {
            _ = particleFilter.predict(
                particles: particles,
                control: control,
                model: model
            )
        }
    }

    func test__weight() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 0.5),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 0.5),
        ]
        let observations = [
            Observation(xyz: [0.0, 0.0, 0.0], measurement: 0.0),
            Observation(xyz: [1.0, 0.0, 0.0], measurement: 1.0),
            Observation(xyz: [0.0, 1.0, 0.0], measurement: 1.0),
            Observation(xyz: [0.0, 0.0, 1.0], measurement: 1.0),
        ]
        let model = ObservationModel(stdDeviation: 0.5)

        let weighted = particleFilter.weight(
            particles: particles,
            observations: observations,
            model: model
        )

        let expected = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 0.0),
        ]

        XCTAssertNearEqual(weighted, expected, accuracy: 0.0001)
    }

    func test__weight__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                xyz: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let observations = [
            Observation(xyz: [0.0, 0.0, 0.0], measurement: 0.0),
            Observation(xyz: [1.0, 0.0, 0.0], measurement: 1.0),
            Observation(xyz: [0.0, 1.0, 0.0], measurement: 1.0),
            Observation(xyz: [0.0, 0.0, 1.0], measurement: 1.0),
        ]
        let model = ObservationModel(stdDeviation: 0.5)

        measure {
            _ = particleFilter.weight(
                particles: particles,
                observations: observations,
                model: model
            )
        }
    }

    func test__evaluate__worstCase() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 0.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 0.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 0.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        let evaluation = particleFilter.evaluate(
            particles: particles,
            model: model
        )

        XCTAssertEqual(evaluation, .impoverished)
    }

    func test__evaluate__bestCase() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 1.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 1.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 1.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        let evaluation = particleFilter.evaluate(
            particles: particles,
            model: model
        )

        XCTAssertEqual(evaluation, .healthy)
    }

    func test__evaluate__belowThreshold() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 0.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        let evaluation = particleFilter.evaluate(
            particles: particles,
            model: model
        )

        XCTAssertEqual(evaluation, .impoverished)
    }

    func test__evaluate__aboveThreshold() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 1.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        let evaluation = particleFilter.evaluate(
            particles: particles,
            model: model
        )

        XCTAssertEqual(evaluation, .healthy)
    }

    func test__evaluate__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                xyz: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let model = EvaluationModel(threshold: 0.5)

        measure {
            _ = particleFilter.evaluate(
                particles: particles,
                model: model
            )
        }
    }

    func test__resample__uniform() {
        let particleFilter = CPUParticleFilter()

        struct ConstantUniformRandom: UniformRandom {
            typealias Value = Double

            let constant: Value

            init(constant: Value) {
                self.constant = constant
            }

            func random() -> Double {
                return constant
            }
        }

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 1.0 / 5.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 1.0 / 5.0),
        ]
        let uniformRandom = ConstantUniformRandom(constant: 0.5)

        let resampled = particleFilter.resample(
            particles: particles,
            uniformRandom: uniformRandom
        )
        let expected = particles

        XCTAssertEqual(resampled, expected)
    }

    func test__resample__nonUniform() {
        let particleFilter = CPUParticleFilter()

        struct ConstantUniformRandom: UniformRandom {
            typealias Value = Double

            let constant: Value

            init(constant: Value) {
                self.constant = constant
            }

            func random() -> Double {
                return constant
            }
        }

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 0.6),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 0.2),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 0.2),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let uniformRandom = ConstantUniformRandom(constant: 0.1)

        let resampled = particleFilter.resample(
            particles: particles,
            uniformRandom: uniformRandom
        )
        let expected = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
        ]

        XCTAssertEqual(resampled, expected)
    }

    func test__resample__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(xyz: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
            Particle(xyz: [3.0, 3.0, 3.0], weight: 1.0 / 5.0),
            Particle(xyz: [4.0, 4.0, 4.0], weight: 1.0 / 5.0),
        ]

        measure {
            _ = particleFilter.resample(particles: particles)
        }
    }

    func test__mean() {
        let particleFilter = CPUParticleFilter()

        // Corners of a unit cube:
        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 0.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 1.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 1.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 0.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 0.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 1.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0 / 8.0),
        ]

        let mean = particleFilter.mean(particles: particles)
        // Center of a unit cube:
        let expected: Particle.Vector = [0.5, 0.5, 0.5]

        XCTAssertNearEqual(mean, expected, accuracy: 0.0001)
    }

    func test__mean__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                xyz: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }

        measure {
            _ = particleFilter.mean(particles: particles)
        }
    }

    func test__variance() {
        let particleFilter = CPUParticleFilter()

        // Corners of a unit cube:
        let particles = [
            Particle(xyz: [0.0, 0.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 0.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 1.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [0.0, 1.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 0.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 0.0, 1.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 1.0, 0.0], weight: 1.0 / 8.0),
            Particle(xyz: [1.0, 1.0, 1.0], weight: 1.0 / 8.0),
        ]
        let mean: Particle.Vector = [0.5, 0.5, 0.5]

        let variance: Particle.Scalar = particleFilter.variance(
            particles: particles,
            mean: mean
        )
        // Center of a unit cube:
        let expected: Particle.Scalar = sqrt(3.0 * (0.5 * 0.5))

        XCTAssertEqual(variance, expected, accuracy: 0.01)
    }

    func test__variance__benchmark() {
        let particleFilter = CPUParticleFilter()

        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                xyz: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let mean: Particle.Vector = [0.0, 0.0, 0.0]

        measure {
            _ = particleFilter.variance(particles: particles, mean: mean)
        }
    }
}
