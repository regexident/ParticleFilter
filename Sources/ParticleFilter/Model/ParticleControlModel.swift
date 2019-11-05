import Surge
import StateSpace
import StateSpaceModel

// MARK: - Protocols

public protocol ParticleControlModel: ControlModelProtocol
    where State == Vector<Double>,
          Control == Vector<Double>
{
    // Nothing
}

extension LinearControlModel: ParticleControlModel {
    // Nothing
}
