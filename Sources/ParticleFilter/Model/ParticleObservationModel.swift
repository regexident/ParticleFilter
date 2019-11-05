import Surge
import StateSpace
import StateSpaceModel

// MARK: - Protocols

public protocol ParticleObservationModel: ObservationModelProtocol
    where State == Vector<Double>, Observation == Vector<Double>
{
    // Nothing
}

// MARK: - Observation Models

extension TransparentObservationModel: ParticleObservationModel {
    // Nothing
}

extension LinearObservationModel: ParticleObservationModel {
    // Nothing
}

extension NonlinearObservationModel: ParticleObservationModel {
    // Nothing
}
