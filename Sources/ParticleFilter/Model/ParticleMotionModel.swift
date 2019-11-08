import Surge
import StateSpace
import StateSpaceModel

// MARK: - Protocols

public protocol ParticleMotionModel: UncontrollableMotionModelProtocol
    where State == Vector<Double>
{
    // Nothing
}

public protocol ControllableParticleMotionModel: ControllableMotionModelProtocol
    where State == Vector<Double>, Control == Vector<Double>
{
    // Nothing
}

// MARK: - Uncontrollable Motion Models

extension ZeroMotionModel: ParticleMotionModel {
    // Nothing
}

extension LinearMotionModel: ParticleMotionModel {
    // Nothing
}

//extension BrownianMotionModel: ParticleMotionModel
//    where MotionModel: ParticleMotionModel
//{
//    // Nothing
//}

extension NonlinearMotionModel: ParticleMotionModel {
    // Nothing
}

// MARK: - Controllable Motion Models

//extension BrownianMotionModel: ControllableParticleMotionModel
//    where MotionModel: ControllableParticleMotionModel
//{
//    // Nothing
//}

extension ControllableLinearMotionModel: ControllableParticleMotionModel
    where MotionModel: ParticleMotionModel, ControlModel: ParticleControlModel
{
    // Nothing
}

extension ControllableNonlinearMotionModel: ControllableParticleMotionModel {
    // Nothing
}
