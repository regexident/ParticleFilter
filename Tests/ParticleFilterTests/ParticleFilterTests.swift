import XCTest

@testable import ParticleFilter

class ParticleFilterTests: XCTestCase {
    let particleCount: Int = 10000
    
    func makeModel() -> Model {
        let motionModel = MotionModel(stdDeviation: 0.0)
        let observationModel = ObservationModel(stdDeviation: 0.5)
        let evaluationModel = EvaluationModel(threshold: 0.5)
        
        return Model(
            motion: motionModel,
            observation: observationModel,
            evaluation: evaluationModel
        )
    }

    func test__predict__staticMotion_zeroControl() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
        ]
        let model = MotionModel(stdDeviation: 0.0)
        let control: Particle.Location = [0.0, 0.0, 0.0]
        
        let predictor = ParticlePredictor()
        let predicted = predictor.predict(
            particles: particles,
            control: control,
            model: model
        )

        let expected = particles

        XCTAssertEqual(predicted, expected)
    }

    func test__predict__staticMotion_nonZeroControl() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
        ]
        let model = MotionModel(stdDeviation: 0.0)
        let control: Particle.Location = [0.1, 0.2, 0.3]

        let predictor = ParticlePredictor()
        let predicted = predictor.predict(
            particles: particles,
            control: control,
            model: model
        )

        let expected = [
            Particle(location: [0.1, 0.2, 0.3], weight: 1.0),
        ]

        XCTAssertEqual(predicted, expected)
    }

    func test__predict__benchmark() {
        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                location: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let model = MotionModel(stdDeviation: 1.0)
        let control: Particle.Location = [0.1, 0.2, 0.3]

        measure {
            let predictor = ParticlePredictor()
            let _ = predictor.predict(
                particles: particles,
                control: control,
                model: model
            )
        }
    }

    func test__weight() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 0.5),
            Particle(location: [1.0, 1.0, 1.0], weight: 0.5),
        ]
        let observations = [
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 0.0, 0.0]),
                measurement: 0.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [1.0, 0.0, 0.0]),
                measurement: 1.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 1.0, 0.0]),
                measurement: 1.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 0.0, 1.0]),
                measurement: 1.0
            ),
        ]
        let model = ObservationModel(stdDeviation: 0.5)

        let weighter = ParticleWeighter()
        let actual = weighter.weight(
            particles: particles,
            observations: observations,
            model: model
        )

        let expected = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 0.0),
        ]
        
        let actualLocations = actual.map { $0.location }
        let expectedLocations = expected.map { $0.location }
        
        let actualWeights = actual.map { $0.weight }
        let expectedWeights = expected.map { $0.weight }
        
        XCTAssertEqual(actualLocations, expectedLocations, accuracy: 0.0001)
        XCTAssertEqual(actualWeights, expectedWeights, accuracy: 0.0001)
    }

    func test__weight__benchmark() {
        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                location: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let observations = [
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 0.0, 0.0]),
                measurement: 0.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [1.0, 0.0, 0.0]),
                measurement: 1.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 1.0, 0.0]),
                measurement: 1.0
            ),
            LandmarkObservation(
                landmark: Landmark(location: [0.0, 0.0, 1.0]),
                measurement: 1.0
            ),
        ]
        let model = ObservationModel(stdDeviation: 0.5)

        measure {
            let weighter = ParticleWeighter()
            let _ = weighter.weight(
                particles: particles,
                observations: observations,
                model: model
            )
        }
    }

    func test__evaluate__worstCase() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 0.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 0.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 0.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        
        let evaluator = ParticleEvaluator()
        
        let actual = evaluator.evaluate(
            particles: particles,
            model: model
        )

        let expected: ParticleFilterEvaluation = .impoverished
        
        XCTAssertEqual(actual, expected)
    }

    func test__evaluate__bestCase() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 1.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 1.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 1.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        
        let evaluator = ParticleEvaluator()
        
        let actual = evaluator.evaluate(
            particles: particles,
            model: model
        )

        let expected: ParticleFilterEvaluation = .healthy
        
        XCTAssertEqual(actual, expected)
    }

    func test__evaluate__belowThreshold() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 0.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        
        let evaluator = ParticleEvaluator()
        
        let actual = evaluator.evaluate(
            particles: particles,
            model: model
        )

        let expected: ParticleFilterEvaluation = .impoverished
        
        XCTAssertEqual(actual, expected)
    }

    func test__evaluate__aboveThreshold() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 1.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        let model = EvaluationModel(threshold: 0.5)
        
        let evaluator = ParticleEvaluator()
        
        let actual = evaluator.evaluate(
            particles: particles,
            model: model
        )

        let expected: ParticleFilterEvaluation = .healthy
        
        XCTAssertEqual(actual, expected)
    }

    func test__evaluate__benchmark() {
        let particles: [Particle] = (0 ..< particleCount).map { i in
            let f = 1.0 / Particle.Scalar(i)
            let weight = 1.0 / Particle.Scalar(self.particleCount)
            return Particle(
                location: [0.0 * f, 1.0 * f, 2.0 * f],
                weight: weight
            )
        }
        let model = EvaluationModel(threshold: 0.5)

        measure {
            let evaluator = ParticleEvaluator()
            let _ = evaluator.evaluate(
                particles: particles,
                model: model
            )
        }
    }

    func test__resample__uniform() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 1.0 / 5.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 1.0 / 5.0),
        ]
        
        var generator = IncrementingRandomNumberGenerator()

        let resampler = ParticleResampler()
        
        let actual = resampler.resample(
            particles: particles,
            using: &generator
        )
        
        let expected = particles

        XCTAssertEqual(actual, expected)
    }

    func test__resample__nonUniform() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 0.6),
            Particle(location: [1.0, 1.0, 1.0], weight: 0.2),
            Particle(location: [2.0, 2.0, 2.0], weight: 0.2),
            Particle(location: [3.0, 3.0, 3.0], weight: 0.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 0.0),
        ]
        
        var generator = IncrementingRandomNumberGenerator()

        let resampler = ParticleResampler()
        
        let actual = resampler.resample(
            particles: particles,
            using: &generator
        )
        
        let expected = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
        ]

        XCTAssertEqual(actual, expected)
    }

    func test__resample__benchmark() {
        let particles = [
            Particle(location: [0.0, 0.0, 0.0], weight: 1.0 / 5.0),
            Particle(location: [1.0, 1.0, 1.0], weight: 1.0 / 5.0),
            Particle(location: [2.0, 2.0, 2.0], weight: 1.0 / 5.0),
            Particle(location: [3.0, 3.0, 3.0], weight: 1.0 / 5.0),
            Particle(location: [4.0, 4.0, 4.0], weight: 1.0 / 5.0),
        ]

        measure {
            let resampler = ParticleResampler()
            let _ = resampler.resample(particles: particles)
        }
    }
}
