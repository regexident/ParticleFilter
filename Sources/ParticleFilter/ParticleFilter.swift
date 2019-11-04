import BayesFilter

import BayesFilter

public protocol ParticleFilterProtocol: BayesFilterProtocol
where
    Estimate == ParticleEstimate
{}

public typealias StatefulParticleFilter<Predictor, Updater> = Estimateful<ParticleFilter<Predictor, Updater>>

public typealias ParticleFilter<Predictor, Updater> = BayesFilter<Predictor, Updater, ParticleEstimate>

extension ParticleFilter: ParticleFilterProtocol
where
    Predictor: ParticlePredictorProtocol,
    Updater: ParticleUpdaterProtocol,
    Predictor.Estimate == ParticleEstimate,
    Updater.Estimate == ParticleEstimate,
    Estimate == ParticleEstimate
{}

extension ParticleFilter: ParticlePredictorProtocol
where
    Predictor: ParticlePredictorProtocol,
    Predictor.Estimate == ParticleEstimate,
    Estimate == ParticleEstimate
{
    public typealias MotionModel = Predictor.MotionModel
}

extension ParticleFilter: ParticleUpdaterProtocol
where
    Updater: ParticleUpdaterProtocol,
    Updater.Estimate == ParticleEstimate,
    Estimate == ParticleEstimate
{
    public typealias ObservationModel = Updater.ObservationModel
}
