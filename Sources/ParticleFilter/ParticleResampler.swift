import Foundation

import Surge

internal struct ParticleResampler: ParticleResamplerProtocol {
    internal typealias ParticleBuffer = [Particle]
    
    internal func resample(particles: ParticleBuffer) -> ParticleBuffer {
        var generator = SystemRandomNumberGenerator()
        return self.resample(particles: particles, using: &generator)
    }
    
    internal func resample<T>(
        particles: ParticleBuffer,
        using generator: inout T
    ) -> ParticleBuffer
        where T: RandomNumberGenerator
    {
        assert(!particles.isEmpty)

        // Implementation of Stochastic Universal Sampling:
        
        var generator = generator
        var resampled: ParticleBuffer = []
        
        let n = particles.count
        let weight = 1.0 / Double(n)
        let totalWeight = particles.reduce(0.0) { $0 + $1.weight }
        let stride = totalWeight / Double(n)
        
        let offset = Double.random(in: 0.0...stride, using: &generator)
        var cursor = particles[0].weight
        var index = 0
        
        for m in 0 ..< n {
            var particle = particles[index]
            let sample = offset + (Double(m) * stride)
            
            while cursor < sample {
                index += 1
                particle = particles[index]
                cursor += particle.weight
            }
            
            resampled.append(particle.with(weight: weight))
        }
        
        return resampled
    }
}
