import Foundation

import Surge
import BayesFilter
import StateSpace
import StateSpaceModel

// swiftlint:disable all identifier_name

public class MultiModalParticleUpdater<Model, ObservationModel>
    where Model: Hashable
{
    public var stdDeviation: Double
    public var threshold: Double

    public var observationModels: [Model: ObservationModel] = [:]
    public var closure: (Model) -> ObservationModel

    public init(
        stdDeviation: Double,
        threshold: Double,
        closure: @escaping (Model) -> ObservationModel
    ) {
        self.stdDeviation = stdDeviation
        self.threshold = threshold
        self.closure = closure
    }

    private func withObservationModel<T>(
        for model: Model,
        _ closure: (ObservationModel) -> T
    ) -> T {
        let observationModel = self.observationModels[model] ?? self.closure(model)
        let result = closure(observationModel)
        self.observationModels[model] = observationModel
        return result
    }
}

extension MultiModalParticleUpdater
    where ObservationModel: ParticleObservationModel
{
    internal static func weight<S>(
        states: [Vector<Double>],
        observations: S,
        stdDeviation: Double,
        particleObservation: (State, Model) -> Vector<Double>
    ) -> [Double]
        where S : Sequence, S.Element == Observation
    {
        assert(!states.isEmpty)
        let cdf = NormalCumulativeDistributionFunction()
        let variance = stdDeviation * stdDeviation
        var totalWeight: Double = 0.000001 // non-zero to avoid divide by zero
        let weights: [Double] = states.map { state in
            let weight = observations.reduce(1.0) { probability, observation in
                let modelObservation = observation.value
                let particleObservation = particleObservation(state, observation.model)
                let delta = modelObservation.distance(to: particleObservation)
                let cdf = cdf.evaluate(mean: 0.0, variance: variance, value: delta)
                return probability * (1.0 - cdf)
            }
            totalWeight += weight
            return weight
        }
        let normalizedWeights = weights.map { $0 / totalWeight }
        return normalizedWeights
    }

    internal static func shouldResample(
        weights: [Double],
        threshold: Double
    ) -> Bool {
        assert(!weights.isEmpty)

        // Neff according to Kong et al. (1994):

        var totalWeights = 0.0
        var totalSquaredWeights = 0.0
        for weight in weights {
            totalWeights += weight
            totalSquaredWeights += weight * weight
        }
        let totalWeightsSquared = totalWeights * totalWeights

        let epsilon = 0.000001

        let neff = totalWeightsSquared / (totalSquaredWeights + epsilon)
        let normalizedNeff = neff / Double(weights.count)

        if normalizedNeff > threshold {
            return true
        } else {
            return false
        }
    }

    internal static func resample(estimate: Estimate) -> Estimate {
        var generator = SystemRandomNumberGenerator()
        return self.resample(estimate: estimate, using: &generator)
    }

    internal static func resample<T>(
        estimate: Estimate,
        using generator: inout T
    ) -> Estimate
        where T: RandomNumberGenerator
    {
        assert(!estimate.isEmpty)

        // Implementation of Stochastic Universal Sampling:

        var generator = generator

        var states: [Vector<Double>] = []
        var weights: [Double] = []

        let n = estimate.count
        let weight = 1.0 / Double(n)
        let totalWeight = estimate.weights.reduce(0.0, +)
        let stride = totalWeight / Double(n)

        let offset = Double.random(in: 0.0...stride, using: &generator)
        var cursor = -offset

        var index = -1

        for i in 0..<n {
            let sample = Double(i) * stride

            while (cursor <= sample) && (index + 1 < n) {
                index += 1
                cursor += estimate.weights[index]
            }

            states.append(estimate.states[index])
            weights.append(weight)
        }

        return Estimate(
            states: states,
            weights: weights
        )
    }
}

extension MultiModalParticleUpdater: DimensionsValidatable {
    public func validate(for dimensions: DimensionsProtocol) throws {
        for observationModel in self.observationModels.values {
            if let observationModel = observationModel as? DimensionsValidatable {
                try observationModel.validate(for: dimensions)
            }
        }
    }
}

extension MultiModalParticleUpdater: Statable {
    public typealias State = Vector<Double>
}

extension MultiModalParticleUpdater: Observable {
    public typealias Observation = MultiModal<Model, Vector<Double>>
}

extension MultiModalParticleUpdater: Estimatable {
    public typealias Estimate = ParticleEstimate
}

extension MultiModalParticleUpdater: BayesUpdaterProtocol, ParticleUpdaterProtocol
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
        let states = prediction.states

        assert(!states.isEmpty)

        // Calculate normalized weights based on observation model:
        let weights = type(of: self).weight(
            states: states,
            observations: observations,
            stdDeviation: self.stdDeviation
        ) { state, model in
            self.withObservationModel(for: model) { model in
                model.apply(state: state)
            }
        }

        // Check if resampling is necessary due to depletion/impoverishment:
        let shouldResample = type(of: self).shouldResample(
            weights: weights,
            threshold: self.threshold
        )

        let estimate = Estimate(states: states, weights: weights)

        guard shouldResample else {
            return estimate
        }

        // Resample particles if particle set has been depleted/impoverished:
        let resampled = type(of: self).resample(
            estimate: estimate
        )

        return resampled
    }
}
