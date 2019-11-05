import Foundation

import Surge
import BayesFilter
import StateSpace
import StateSpaceModel

// swiftlint:disable all identifier_name

public class ParticleFilter<Predictor, Updater>: EstimateReadWritable {
    public typealias Filter = BayesFilter<Predictor, Updater, Estimate>

    public var estimate: Estimate
    public var filter: Filter

    public init(
        estimate: Estimate,
        predictor: Predictor,
        updater: Updater
    ) {
        self.estimate = estimate
        self.filter = BayesFilter(
            predictor: predictor,
            updater: updater
        )
    }
}

extension ParticleFilter: DimensionsValidatable {
    public func validate(for dimensions: DimensionsProtocol) throws {
        try self.filter.validate(for: dimensions)
    }
}

extension ParticleFilter: Statable {
    public typealias State = Vector<Double>
}

extension ParticleFilter: Controllable
    where Predictor: Controllable
{
    public typealias Control = Predictor.Control
}

extension ParticleFilter: Observable
    where Updater: Observable
{
    public typealias Observation = Updater.Observation
}

extension ParticleFilter: Estimatable {
    public typealias Estimate = ParticleEstimate
}

extension ParticleFilter: BayesPredictorProtocol
    where Predictor: BayesPredictorProtocol,
          Predictor.Estimate == Estimate
{
    public func predicted(estimate: Estimate) -> Estimate {
        return self.filter.predicted(
            estimate: estimate
        )
    }
}

extension ParticleFilter: ControllableBayesPredictorProtocol
    where Predictor: ControllableBayesPredictorProtocol,
          Predictor.Estimate == Estimate
{
    public func predicted(
        estimate: Estimate,
        control: Control
    ) -> Estimate {
        return self.filter.predicted(
            estimate: estimate,
            control: control
        )
    }
}

extension ParticleFilter: BayesUpdaterProtocol
    where Updater: BayesUpdaterProtocol,
          Updater.Estimate == Estimate
{
    public func updated(
        prediction: Estimate,
        observation: Observation
    ) -> Estimate {
        return self.filter.updated(
            prediction: prediction,
            observation: observation
        )
    }
}

extension ParticleFilter: BayesFilterProtocol
    where Predictor: BayesPredictorProtocol,
          Updater: BayesUpdaterProtocol,
          Predictor.Estimate == Estimate,
          Updater.Estimate == Estimate
{
    public func filtered(
        estimate: Estimate,
        observation: Observation
    ) -> Estimate {
        return self.filter.filtered(
            estimate: estimate,
            observation: observation
        )
    }
}

extension ParticleFilter: ControllableBayesFilterProtocol
    where Predictor: ControllableBayesPredictorProtocol,
          Updater: BayesUpdaterProtocol,
          Predictor.Estimate == Estimate,
          Updater.Estimate == Estimate
{
    public func filtered(
        estimate: Estimate,
        control: Control,
        observation: Observation
    ) -> Estimate {
        return self.filter.filtered(
            estimate: estimate,
            control: control,
            observation: observation
        )
    }
}
