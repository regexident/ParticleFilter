import XCTest

import Surge
import StateSpace
import StateSpaceModel

@testable import ParticleFilter

/// Modelled after:
/// https://github.com/balzer82/Kalman/blob/master/Kalman-Filter-CV.ipynb
final class LinearVelocityModelTests: XCTestCase {
    typealias MotionModel = ControllableLinearMotionModel<LinearMotionModel, LinearControlModel>
    typealias ObservationModel = LinearObservationModel

    let time: Double = 0.1 // time delta
    let velocity: (x: Double, y: Double) = (
        x: 20.0, // velocity on x-axis
        y: 10.0 // velocity on y-axis
    ) // in m/s

    let dimensions: Dimensions = .init(
        state: 4, // [position x, position y, velocity x, velocity y]
        control: 2, // [velocity x, velocity y]
        observation: 2 // [position x, position y]
    )

    lazy var motionModel: MotionModel = .init(
        a: [
            [1.0, 0.0, self.time, 0.0],
            [0.0, 1.0, 0.0, self.time],
            [0.0, 0.0, 0.0, 0.0],
            [0.0, 0.0, 0.0, 0.0],
        ],
        b: [
            [0.0, 0.0],
            [0.0, 0.0],
            [self.time, 0.0],
            [0.0, self.time],
        ]
    )

    let observationModel: ObservationModel = .init(
        state: [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
        ]
    )

    lazy var processNoise: Matrix<Double> = {
        let accel = 1.0 // max expected acceleration in m/sec^2
        let qs: Matrix<Double> = [
            [accel * 0.5 * self.time * self.time], // translation in m (double-integrated acceleration)
            [accel * 0.5 * self.time * self.time], // translation in m (double-integrated acceleration)
            [accel * self.time], // velocity in m/s (integrated acceleration)
            [accel * self.time], // velocity in m/s (integrated acceleration)
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

    let stdDeviation: Double = 1.0
    let threshold: Double = 0.5

    let particleCount: Int = 1000

    func filter(control: (Int) -> Vector<Double>) -> Double {
        let initialState: Vector<Double> = [
            0.0, // Position X
            0.0, // Position Y
            0.0, // Velocity X
            0.0, // Velocity Y
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
        let controls: [Vector<Double>] = (0..<sampleCount).map(control)

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

        var particleFilter = ParticleFilter(
            estimate: estimate,
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

        let filteredStates: [Vector<Double>] = Swift.zip(controls, observations).map { argument in
            let (control, observation) = argument
            particleFilter.filter(control: control, observation: observation)
            return particleFilter.estimate.mean
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
            let x = self.velocity.x
            let y = self.velocity.y
            return Vector([x, y])
        }

        XCTAssertLessThan(similarity, 0.5)
    }

    func testVariableModel() {
        let similarity = self.filter { i in
            let sine = sin(Double(i) * 0.1) * 0.5 + 0.5 // sine-wave from 0.0..1.0
            let cosine = cos(Double(i) * 0.1) * 0.5 + 0.5 // cosine-wave from 0.0..1.0
            let x = self.velocity.x * sine
            let y = self.velocity.y * cosine
            return Vector([x, y])
        }

        XCTAssertLessThan(similarity, 0.5)
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
