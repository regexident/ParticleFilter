import Darwin

extension Double {
    static func stdGaussianRandom() -> Double {
        let a = Double.random(in: 0.0 ..< 1.0)
        let b = Double.random(in: 0.0 ..< 1.0)
        let c = Double.random(in: 0.0 ..< 1.0)

        let d = abs(-2.0 * log(a))
        let e = 2.0 * .pi * b

        if c < 0.5 {
            return sqrt(d) * sin(e)
        } else {
            return sqrt(d) * cos(e)
        }
    }

    static func gaussianRandom(mean: Double, stdDev: Double) -> Double {
        let stdRandom = stdGaussianRandom()
        return mean + (stdRandom * stdDev)
    }
}

internal protocol RandomSource {
    associatedtype Value

    func next() -> Value
}

public class CPUParticleFilter {
    public init() {
        // nothing
    }
}

extension CPUParticleFilter: ParticleFilterProtocol {
    public func filter(
        particles: [Particle],
        observations: [Observation],
        model: Model,
        control: Particle.Vector
    ) -> ParticleFilterOutput {
        var particles = particles

        // Predict particle movement based on motion model:
        particles = predict(
            particles: particles,
            control: control,
            model: model.motion
        )

        // Calculate normalized weights based on observation model:
        particles = weight(
            particles: particles,
            observations: observations,
            model: model.observation
        )

        // Check if resampling is necessary due to depletion:
        if !evaluate(particles: particles, model: model.evaluation) {
            // Resample particles:
            particles = resample(particles: particles)
        }

        // Calculate estimated coordinate:
        let estimate = self.estimate(particles: particles)

        // Calculate variance of particles:
        let variance = self.variance(
            particles: particles,
            mean: estimate
        )

        return ParticleFilterOutput(
            estimate: estimate,
            particles: particles,
            variance: variance
        )
    }

    public func predict(
        particles: [Particle],
        control: Particle.Vector,
        model: MotionModel
    ) -> [Particle] {
        let stdDeviation = model.stdDeviation
        return particles.map { particle in
            let noiseX = Double.gaussianRandom(mean: 0.0, stdDev: stdDeviation)
            let noiseY = Double.gaussianRandom(mean: 0.0, stdDev: stdDeviation)
            let noiseZ = Double.gaussianRandom(mean: 0.0, stdDev: stdDeviation)
            let noise = Double3(x: noiseX, y: noiseY, z: noiseZ)

            let xyz = particle.xyz + noise + control
            let weight = particle.weight

            return Particle(xyz: xyz, weight: weight)
        }
    }

    public func weight(
        particles: [Particle],
        observations: [Observation],
        model: ObservationModel
    ) -> [Particle] {
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
        return Swift.zip(particles, weights).map { $0.with(weight: $1 / totalWeight) }
    }

    public func evaluate(
        particles: [Particle],
        model: EvaluationModel
    ) -> Bool {
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

        return normalizedNeff > model.threshold
    }

    public func resample(particles: [Particle]) -> [Particle] {
        struct DefaultSource: RandomSource {
            typealias Value = Double

            let range: Range<Value>

            init(range: Range<Value>) {
                self.range = range
            }

            func next() -> Double {
                return Double.random(in: range)
            }
        }

        let randomSource = DefaultSource(range: 0.0 ..< 1.0)

        return resample(
            particles: particles,
            randomSource: randomSource
        )
    }

    // low-variance resampling, based on uniform importance sampling.
    internal func resample<T>(
        particles: [Particle],
        randomSource: T
    ) -> [Particle]
        where T: RandomSource, T.Value == Double {
        assert(particles.count == particles.count)

        var resampled: [Particle] = []

        let n = particles.count
        let weight = 1.0 / Double(n)
        let totalWeight = particles.reduce(0.0) { $0 + $1.weight }
        let stride = totalWeight / Double(n)

        let offset = randomSource.next() * stride
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

    public func estimate(
        particles: [Particle]
    ) -> Particle.Vector {
        let weight = 1.0 / Double(particles.count)
        let coordinate: Double3 = particles.reduce(.zero) {
            $0 + ($1.xyz * weight)
        }
        return coordinate
    }

    public func variance(
        particles: [Particle],
        mean: Particle.Vector
    ) -> Double {
        assert(!particles.isEmpty)
        // 1.0 / (n - 1.0)
        let weight = 1.0 / (Double(particles.count - 1) + 0.0001)
        return particles.reduce(0.0) {
            let delta = $1.xyz.distance(to: mean)
            return $0 + ((delta * delta) * weight)
        }
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
