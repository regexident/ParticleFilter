import XCTest

import Surge
import StateSpace
import StateSpaceModel

@testable import ParticleFilter

private func deg2rad(_ degree: Double) -> Double {
    return (degree / 180.0) * .pi
}

/// Modelled after:
/// https://github.com/balzer82/Kalman/blob/master/Extended-Kalman-Filter-CTRA.ipynb
final class NonlinearYawAccelerationModelTests: XCTestCase {
    typealias MotionModel = ControllableNonlinearMotionModel
    typealias ObservationModel = LinearObservationModel

    let time: Double = 0.1 // time delta
    let acceleration: Double = 1.0 // in m/s^2
    let yaw: Double = deg2rad(30.0) // yaw rate in radians/s^2

    let dimensions: Dimensions = .init(
        state: 6, // [position x, position y, h, velocity, yaw rate, acceleration]
        control: 2, // [yaw rate, acceleration]
        observation: 2 // [position x, position y]
    )

    lazy var motionModel: MotionModel = .init(dimensions: self.dimensions) { state, control in
        let (x, y, h, v) = (state[0], state[1], state[2], state[3]) // pos-x, pos-y, heading, velocity
        let (w, a) = (control[0], control[1]) // yaw-rate, acceleration
        let t = self.time // delta time
        return [
            x + (v / w) * (sin(h + w * t) - sin(h)),
            y + (v / w) * (-cos(h + w * t) + cos(h)),
            h + w * t,
            v + a * t,
            w,
            a,
        ]
    }

    let observationModel: ObservationModel = .init(
        state: [
            [1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0, 0.0, 0.0],
        ]
    )

    lazy var processNoise: Matrix<Double> = {
        let acceleration = 1.0 // max expected acceleration in m/sec^2
        let yaw = 0.1 // max expected yaw in radians/s^2
        let qs: Matrix<Double> = [
            [acceleration * (0.5 * self.time * self.time)], // translation in m (double-integrated acceleration)
            [acceleration * (0.5 * self.time * self.time)], // translation in m (double-integrated acceleration)
            [yaw * self.time], // heading in radians/s (integrated of yaw)
            [acceleration * self.time], // velocity in m/s (integrated acceleration)
            [yaw * 1.0], // yaw in radians/s^2
            [acceleration * 1.0], // acceleration in m/s^2
        ]
        return pow((qs * transpose(qs)), 2.0)
    }()

    lazy var observationNoise: Matrix<Double> = pow(Matrix.diagonal(
        rows: dimensions.observation,
        columns: dimensions.observation,
        repeatedValue: 2.0
    ), 2.0)

    lazy var brownianNoise: Vector<Double> = .init(
        dimensions: self.dimensions.state,
        repeatedValue: 1.0
    )

    let stdDeviation: Double = 2.0
    let threshold: Double = 0.5

    let particleCount: Int = 1000

    func filter(control: (Int) -> Vector<Double>) -> Double {
        let initialState: Vector<Double> = [
            0.0, // Position X
            0.0, // Position Y
            0.0, // Heading
            0.0, // Velocity
            0.0, // Yaw Rate
            0.0, // Acceleration
        ]

//        let estimate: ParticleEstimate = .init(
//            states: (0..<self.particleCount).map { _ in
//                Vector(random: self.dimensions.state)
//            }
//        )

        let estimate: ParticleEstimate = .init(
            states: Array(repeating: initialState, count: self.particleCount)
        )

        let sampleCount = 200
        let controls: [Vector<Double>] = (0..<sampleCount).map { i in
            let yaw = self.yaw
            let acceleration = self.acceleration
            return Vector([yaw, acceleration])
        }

        let states = self.makeSignal(
            initial: initialState,
            controls: controls,
            model: self.motionModel,
            processNoise: self.processNoise
        )

        let observations: [Vector<Double>] = states.map { state in
            let observation: Vector<Double> = self.observationModel.apply(state: state)
            let standardNoise: Vector<Double> = Vector(gaussianRandom: self.dimensions.observation)
            let noise: Vector<Double> = self.observationNoise * standardNoise
            return observation + noise
        }

        let particleFilter = ParticleFilter(
            predictor: ParticlePredictor(
                motionModel: self.motionModel,
                brownianNoise: self.brownianNoise
            ),
            updater: ParticleUpdater(
                observationModel: self.observationModel,
                stdDeviation: self.stdDeviation,
                threshold: self.threshold
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
            let yaw = self.yaw
            let acceleration = self.acceleration
            return Vector([yaw, acceleration])
        }

        XCTAssertLessThan(similarity, 2.0)
    }

    func testVariableModel() {
        let similarity = self.filter { i in
            let sine = sin(Double(i) * 0.1) * 0.5 + 0.5 // sine-wave from 0.0..1.0
            let cosine = cos(Double(i) * 0.1) * 0.5 + 0.5 // cosine-wave from 0.0..1.0
            let yaw = self.yaw * sine
            let acceleration = self.acceleration * cosine
            return Vector([yaw, acceleration])
        }

        XCTAssertLessThan(similarity, 5.0)
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
