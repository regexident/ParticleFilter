import Foundation

import Surge

internal struct ParticlePredictor: ParticlePredictorProtocol {
    internal typealias Control = Particle.Location
    internal typealias ParticleBuffer = [Particle]
    
    internal func predict(
        particles: ParticleBuffer,
        control: Control,
        model: MotionModel
    ) -> ParticleBuffer {
        var generator = SystemRandomNumberGenerator()
        return self.predict(
            particles: particles,
            control: control,
            model: model,
            using: &generator
        )
    }
    
    internal func predict<T>(
        particles: ParticleBuffer,
        control: Control,
        model: MotionModel,
        using generator: inout T
    ) -> ParticleBuffer
        where T: RandomNumberGenerator
    {
        assert(!particles.isEmpty)
        
        typealias Scalar = Particle.Scalar
        
        var generator = generator
        let stdDeviation = model.stdDeviation
        
        let predicted: ParticleBuffer = particles.map { particle in
            let dimensions = particle.location.dimensions

            // FIXME: Migrate to Surge's own randomization API, once available:
            let noise = Vector((0..<dimensions).map { _ in
                Scalar.normalRandom(
                    mean: 0.0,
                    stdDeviation: stdDeviation,
                    using: &generator
                )
            })

            /// The following optimizied code is equivalent to:
            /// ```
            /// let location = particle.location + noise + control
            /// ```

            var location = particle.location
            location += noise
            location += control

            let weight = particle.weight
            
            return Particle(location: location, weight: weight)
        }
        
        return predicted
    }
}
