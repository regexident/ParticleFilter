import Foundation

public class CPUParticleFilter {
    public weak var delegate: ParticleFilterDelegate? = nil
    
    public init() {
        // nothing
    }
    
    internal func predict(
        particles: [Particle],
        control: Particle.Vector,
        model: MotionModel
    ) -> [Particle] {
        assert(!particles.isEmpty)
        
        let gaussianRandom = DefaultGaussianRandom()
        return self.predict(
            particles: particles,
            control: control,
            model: model,
            gaussianRandom: gaussianRandom
        )
    }
    
    internal func predict<T>(
        particles: [Particle],
        control: Particle.Vector,
        model: MotionModel,
        gaussianRandom: T
    ) -> [Particle]
        where T: GaussianRandom, T.Value == Double
    {
        assert(!particles.isEmpty)
        
        var gaussianRandom = gaussianRandom
        let stdDeviation = model.stdDeviation
        
        let predicted: [Particle] = particles.map { particle in
            let noiseX = gaussianRandom.random(mean: 0.0, stdDeviation: stdDeviation)
            let noiseY = gaussianRandom.random(mean: 0.0, stdDeviation: stdDeviation)
            let noiseZ = gaussianRandom.random(mean: 0.0, stdDeviation: stdDeviation)
            let noise = Double3(x: noiseX, y: noiseY, z: noiseZ)
            
            let xyz = particle.xyz + noise + control
            let weight = particle.weight
            
            return Particle(xyz: xyz, weight: weight)
        }
        
        self.delegate?.particleFilter(self, didPredict: predicted)
        
        return predicted
    }

    internal func weight(
        particles: [Particle],
        observations: [Observation],
        model: ObservationModel
    ) -> [Particle] {
        assert(!particles.isEmpty)
        
        let stdDeviation = model.stdDeviation
        let variance = stdDeviation * stdDeviation
        let weights = particles.map { particle in
            observations.reduce(1.0) { probability, observation in
                let value = particle.xyz.distance(to: observation.xyz)
                let delta = abs(value - observation.measurement)
                let cdf = self.cdf(mean: 0.0, variance: variance, value: delta)
                return probability * (1.0 - cdf)
            }
        }
        let epsilon = 0.000001
        let totalWeight = weights.reduce(0.0) { $0 + $1 } + epsilon
        let weighted: [Particle] = Swift.zip(particles, weights).map { particle, weight in
            particle.with(weight: weight / totalWeight)
        }
        
        self.delegate?.particleFilter(self, didWeight: weighted)
        
        return weighted
    }

    internal func evaluate(
        particles: [Particle],
        model: EvaluationModel
    ) -> ParticleFilterEvaluation {
        assert(!particles.isEmpty)

        // Neff according to Kong et al. (1994):

        var totalWeights = 0.0
        var totalSquaredWeights = 0.0
        for particle in particles {
            let weight = particle.weight
            totalWeights += weight
            totalSquaredWeights += weight * weight
        }
        let totalWeightsSquared = totalWeights * totalWeights

        let epsilon = 0.000001

        let neff = totalWeightsSquared / (totalSquaredWeights + epsilon)
        let normalizedNeff = neff / Double(particles.count)

        let evaluation: ParticleFilterEvaluation
        if normalizedNeff > model.threshold {
            evaluation = .healthy
        } else {
            evaluation = .impoverished
        }
        
        self.delegate?.particleFilter(self, didEvaluate: evaluation)
        
        return evaluation
    }

    internal func resample(particles: [Particle]) -> [Particle] {
        assert(!particles.isEmpty)
        
        let uniformRandom = DefaultUniformRandom()
        return self.resample(
            particles: particles,
            uniformRandom: uniformRandom
        )
    }

    // low-variance resampling, based on uniform importance sampling.
    internal func resample<T>(
        particles: [Particle],
        uniformRandom: T
    ) -> [Particle]
        where T: UniformRandom, T.Value == Double
    {
        assert(!particles.isEmpty)
        
        var uniformRandom = uniformRandom
        var resampled: [Particle] = []

        let n = particles.count
        let weight = 1.0 / Double(n)
        let totalWeight = particles.reduce(0.0) { $0 + $1.weight }
        let stride = totalWeight / Double(n)

        let offset = uniformRandom.random() * stride
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

        self.delegate?.particleFilter(self, didResample: resampled)
        
        return resampled
    }

    internal func mean(
        particles: [Particle]
    ) -> Particle.Vector {
        assert(!particles.isEmpty)
        
        let weight = 1.0 / Double(particles.count)
        let mean: Double3 = particles.reduce(.zero) {
            $0 + ($1.xyz * weight)
        }
        
        self.delegate?.particleFilter(self, didCalculateMean: mean)
        
        return mean
    }

    internal func variance(
        particles: [Particle],
        mean: Particle.Vector
    ) -> Double {
        assert(!particles.isEmpty)
        
        // 1.0 / (n - 1.0)
        let weight = 1.0 / (Double(particles.count - 1) + 0.0001)
        let variance: Double = particles.reduce(0.0) {
            let delta = $1.xyz.distance(to: mean)
            return $0 + ((delta * delta) * weight)
        }
        
        self.delegate?.particleFilter(self, didCalculateVariance: variance)
        
        return variance
    }

    // normal cumulative distribution function:
    internal func cdf(
        mean: Double,
        variance: Double,
        value: Double
    ) -> Double {
        func signum(val: Double) -> Double {
            let lhs = (val > 0.0) ? 1.0 : 0.0
            let rhs = (val < 0.0) ? 1.0 : 0.0
            return lhs - rhs
        }

        let epsilon = 0.000001
        let variance = variance + epsilon
        let delta = value - mean
        let base = 0.5 * (1.0 + signum(val: value - mean))
        let exponent = -((2.0 / .pi) * (delta * delta) / variance)
        let cdf = base * sqrt(1.0 - exp(exponent))
        return cdf
    }
}

extension CPUParticleFilter: ParticleFilterProtocol {
    public func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        assert(!particles.isEmpty)
        
        var particles = particles

        // Predict particle movement based on motion model:
        particles = self.predict(
            particles: particles,
            control: control,
            model: model.motion
        )

        // Calculate normalized weights based on observation model:
        particles = self.weight(
            particles: particles,
            observations: observations,
            model: model.observation
        )

        // Check if resampling is necessary due to depletion:
        let evaluation = self.evaluate(particles: particles, model: model.evaluation)
        
        // Resample particles if particle set has been impoverished:
        if evaluation == .impoverished {
            particles = self.resample(particles: particles)
        }

        // Calculate estimated coordinate:
        let mean = self.mean(particles: particles)

        // Calculate variance of particles:
        let variance = self.variance(
            particles: particles,
            mean: mean
        )
        
        let estimate = ParticleFilterEstimate(
            mean: mean,
            variance: variance
        )

        return ParticleFilterOutput(
            estimate: estimate,
            particles: particles
        )
    }
}
