import Foundation

import Surge
import BayesFilter
import StateSpace
import StateSpaceModel

// swiftlint:disable all identifier_name

public protocol ParticleUpdaterProtocol: BayesUpdaterProtocol {
    associatedtype ObservationModel: ParticleObservationModel
}

private struct UniformModel: Equatable, Hashable {}

public typealias StatefulParticleUpdater<ObservationModel> = Estimateful<ParticleUpdater<ObservationModel>>

public class ParticleUpdater<ObservationModel> {
    public var observationModel: ObservationModel {
        self.multiModal.observationModels[UniformModel()]!
    }

    public var stdDeviation: Double {
        self.multiModal.stdDeviation
    }

    public var threshold: Double {
        self.multiModal.threshold
    }

    private let multiModal: MultiModalParticleUpdater<UniformModel, ObservationModel>

    public convenience init(
        observationModel: ObservationModel,
        stdDeviation: Double,
        threshold: Double
    ) {
        let generator = SystemRandomNumberGenerator()
        self.init(
            observationModel: observationModel,
            stdDeviation: stdDeviation,
            threshold: threshold,
            generator: generator
        )
    }

    public init<T>(
        observationModel: ObservationModel,
        stdDeviation: Double,
        threshold: Double,
        generator: T
    )
    where
        T: RandomNumberGenerator
    {
        self.multiModal = MultiModalParticleUpdater(
            stdDeviation: stdDeviation,
            threshold: threshold,
            generator: generator
        ) { model in
            return observationModel
        }
    }
}

extension ParticleUpdater: DimensionsValidatable {
    public func validate(for dimensions: DimensionsProtocol) throws {
        try self.multiModal.validate(for: dimensions)
    }
}

extension ParticleUpdater: Statable {
    public typealias State = Vector<Double>
}

extension ParticleUpdater: Observable {
    public typealias Observation = Vector<Double>
}

extension ParticleUpdater: Estimatable {
    public typealias Estimate = ParticleEstimate
}

extension ParticleUpdater: BayesUpdaterProtocol, ParticleUpdaterProtocol
    where ObservationModel: ParticleObservationModel
{
    public func updated(
        prediction: Estimate,
        observation: Observation
    ) -> Estimate {
        let observations = CollectionOfOne(observation)
        return self.batchUpdated(
            prediction: prediction,
            observations: observations
        )
    }

    public func batchUpdated<S>(
        prediction: ParticleEstimate,
        observations: S
    ) -> ParticleEstimate
        where S : Sequence, S.Element == Observation
    {
        let model = UniformModel()
        let observations = observations.lazy.map { observation in
            MultiModal(model: model, value: observation)
        }
        return self.multiModal.batchUpdated(
            prediction: prediction,
            observations: observations
        )
    }
}
