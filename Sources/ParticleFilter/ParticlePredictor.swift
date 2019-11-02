import Foundation

import Surge
import BayesFilter
import StateSpace
import StateSpaceModel

// swiftlint:disable all identifier_name

public protocol ParticlePredictorProtocol: BayesPredictorProtocol {
    associatedtype MotionModel: ParticleMotionModel
}

public protocol ControllableParticlePredictorProtocol: ControllableBayesPredictorProtocol {
    associatedtype MotionModel: ControllableParticleMotionModel
}

public class ParticlePredictor<MotionModel> {
    /// Motion model (used for prediction).
    public var motionModel: BrownianMotionModel<MotionModel>

    public init(
        motionModel: MotionModel,
        brownianNoise: Vector<Double>
    ) {
        self.motionModel = BrownianMotionModel(
            motionModel: motionModel,
            stdDeviations: brownianNoise
        )
    }

    /// Predicts next state using current state and control and calculates probability estimate.
    ///
    /// Implements the following literature formulas:
    ///
    /// ```
    /// x'(k) = A * x(k-1) + B * u(k).
    /// ```
    private func predicted(
        estimate: Estimate,
        applyModel: (Vector<Double>) -> Vector<Double>
    ) -> Estimate {
        let states = estimate.states.map { applyModel($0) }
        return ParticleEstimate(
            states: states,
            weights: estimate.weights
        )
    }
}

extension ParticlePredictor: DimensionsValidatable {
    public func validate(for dimensions: DimensionsProtocol) throws {
        try self.motionModel.validate(for: dimensions)
    }
}

extension ParticlePredictor: Statable {
    public typealias State = Vector<Double>
}

extension ParticlePredictor: Controllable {
    public typealias Control = Vector<Double>
}

extension ParticlePredictor: Estimatable {
    public typealias Estimate = ParticleEstimate
}

extension ParticlePredictor: BayesPredictorProtocol, ParticlePredictorProtocol
    where MotionModel: ParticleMotionModel
{
    public func predicted(estimate: Estimate) -> Estimate {
        return self.predicted(estimate: estimate) { (x: Vector<Double>) in
            return self.motionModel.apply(state: x)
        }
    }
}

extension ParticlePredictor: ControllableBayesPredictorProtocol, ControllableParticlePredictorProtocol
    where MotionModel: ControllableParticleMotionModel
{
    public func predicted(estimate: Estimate, control: Control) -> Estimate {
        let u = control
        return self.predicted(estimate: estimate) { x in
            return self.motionModel.apply(state: x, control: u)
        }
    }
}
