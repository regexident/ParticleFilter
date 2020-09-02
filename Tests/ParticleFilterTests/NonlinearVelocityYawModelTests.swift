import XCTest

import Surge
import StateSpace
import StateSpaceModel

@testable import ParticleFilter

private func deg2rad(_ degree: Double) -> Double {
    return (degree / 180.0) * .pi
}

/// Modelled after:
/// https://github.com/balzer82/Kalman/blob/master/Extended-Kalman-Filter-CTRV.ipynb
final class NonlinearVelocityYawModelTests: XCTestCase {
    typealias MotionModel = ControllableNonlinearMotionModel
    typealias ObservationModel = LinearObservationModel

    let time: Double = 0.1 // time delta
    let velocity: Double = 5.0 // in m/s
    let yaw: Double = deg2rad(20.0) // yaw rate in radians/s^2

    let dimensions: Dimensions = .init(
        state: 5, // [position x, position y, h, velocity, yaw rate]
        control: 2, // [velocity, yaw rate]
        observation: 2 // [position x, position y]
    )

    lazy var motionModel: MotionModel = .init(dimensions: self.dimensions) { state, control in
        let (x, y, h) = (state[0], state[1], state[2]) // pos-x, pos-y, heading
        let (v, w) = (control[0], control[1]) // velocity, yaw-rate
        return [
            x + (v / w) * (sin(h + w * self.time) - sin(h)),
            y + (v / w) * (-cos(h + w * self.time) + cos(h)),
            h + w * self.time,
            v,
            w,
        ]
    }

    let observationModel: ObservationModel = .init(
        state: [
            [1.0, 0.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0, 0.0],
        ]
    )

    lazy var processNoiseStdDeviations: Vector<Double> = {
        let acceleration = 1.0 // max expected acceleration in m/sec^2
        let yaw = 0.1 // max expected yaw in radians/s^2
        let time = self.time
        return [
            acceleration * 0.5 * time * time, // translation in m (double-integrated acceleration)
            acceleration * 0.5 * time * time, // translation in m (double-integrated acceleration)
            yaw * time, // heading in radians/s (integrated of yaw)
            acceleration * time, // velocity in m/s (integrated acceleration)
            yaw * 1.0, // yaw in radians/s^2
        ]
    }()

    lazy var processNoiseCovariance: Matrix<Double> = {
        let variance = pow(self.processNoiseStdDeviations, 2.0)
        return Matrix.diagonal(
            rows: self.dimensions.state,
            columns: self.dimensions.state,
            scalars: variance
        )
    }()

    lazy var observationNoiseStdDeviations: Vector<Double> = {
        return [
            1.0, // position x
            1.0, // position y
        ]
    }()

    lazy var observationNoiseCovariance: Matrix<Double> = {
        let variance = pow(self.observationNoiseStdDeviations, 2.0)
        return Matrix.diagonal(
            rows: self.dimensions.observation,
            columns: self.dimensions.observation,
            scalars: variance
        )
    }()

    let threshold: Double = 0.75

    let particleCount: Int = 100

    func filter(control: (Int) -> Vector<Double>) -> Double {
        var generator = DeterministicRandomNumberGenerator(seed: (0, 1, 2, 3))
        
        let initialState: Vector<Double> = [
            0.0, // Position X
            0.0, // Position Y
            0.0, // Heading
            0.0, // Velocity
            0.0, // Yaw Rate
        ]

//        let estimate: ParticleEstimate = .init(
//            states: (0..<self.particleCount).map { _ in
//                Vector(random: self.dimensions.state)
//            }
//        )

        let estimate: ParticleEstimate = .init(
            states: Array(repeating: initialState, count: self.particleCount)
        )

        let sampleCount = 250
        let controls: [Vector<Double>] = (0..<sampleCount).map(control)

        let states = self.makeSignal(
            initial: initialState,
            controls: controls,
            model: self.motionModel,
            processNoise: self.processNoiseCovariance
        )

        let observations: [Vector<Double>] = states.map { state in
            let observation: Vector<Double> = self.observationModel.apply(state: state)
            let standardNoise: Vector<Double> = .randomNormal(
                count: self.dimensions.observation,
                using: &generator
            )
            let noise: Vector<Double> = self.observationNoiseCovariance * standardNoise
            return observation + noise
        }

        let particleFilter = ParticleFilter(
            predictor: ParticlePredictor(
                motionModel: self.motionModel,
                processNoise: self.processNoiseStdDeviations,
                generator: generator
            ),
            updater: ParticleUpdater(
                observationModel: self.observationModel,
                observationNoise: self.observationNoiseStdDeviations,
                threshold: self.threshold,
                generator: generator
            )
        )

        var statefulParticleFilter = StatefulParticleFilter(
            estimate: estimate,
            wrapping: particleFilter
        )

        let filteredStates: [Vector<Double>] = Swift.zip(controls, observations).map { argument in
            let (control, observation) = argument
            statefulParticleFilter.filter(control: control, observation: observation)
            return statefulParticleFilter.estimate.mean
        }

//        self.printSheetAndFail(
//            trueStates: states,
//            estimatedStates: filteredStates,
//            observations: observations
//        )

        let (similarity, _) = autoCorrelation(
            between: states,
            and: filteredStates,
            within: 10
        ) {
            $0.distance(to: $1)
        }

        return similarity
    }

    func testConstantModel() {
        let similarity = self.filter { i in
            let velocity = self.velocity
            let yaw = self.yaw
            return Vector([velocity, yaw])
        }

        XCTAssertEqual(similarity, 0.3, accuracy: 0.1)
    }

    func testVariableModel() {
        let similarity = self.filter { i in
            let sine = sin(Double(i) * 0.1) * 0.5 + 0.5 // sine-wave from 0.0..1.0
            let cosine = cos(Double(i) * 0.1) * 0.5 + 0.5 // cosine-wave from 0.0..1.0
            let velocity = self.velocity * sine
            let yaw = self.yaw * cosine
            return Vector([velocity, yaw])
        }

        XCTAssertEqual(similarity, 0.1, accuracy: 0.1)
    }

    private func printSheetAndFail(
        trueStates: [Vector<Double>],
        estimatedStates: [Vector<Double>],
        observations: [Vector<Double>]? = nil
    ) {
        self.printSheet(trueStates: trueStates, estimatedStates: estimatedStates, observations: observations)

        XCTFail("Printing found in test")
    }

    static var allTests = [
        ("testConstantModel", testConstantModel),
        ("testVariableModel", testVariableModel),
    ]
}
