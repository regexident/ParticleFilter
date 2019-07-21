import Foundation

import Surge

extension Collection where Element == Particle {    
    /// Calculates the mean of particle cloud:
    ///
    /// - Parameters:
    ///   - weighted: Whether to consider individual particle weights.
    public func mean(weighted: Bool = false) -> Particle.Location {
        assert(!self.isEmpty)
        
        // https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Mathematical_definition
        
        guard let firstParticle = self.first else {
            fatalError("An empty collection does not have a mean")
        }
        
        var totalWeight: Double = 0.0
        let uniformWeight = 1.0 / Double(self.count)
        let dimensions = firstParticle.location.dimensions
        var mean = Vector(dimensions: dimensions, repeatedValue: 0.0)
        
        for particle in self {
            let weight = weighted ? particle.weight : uniformWeight
            
            mean += weight * particle.location
            totalWeight += weight
        }
        
        return mean / totalWeight
    }
    
    /// Calculates the variance from the `mean`:
    ///
    /// - Parameters
    ///   - mean: The mean to calculate the variance from.
    public func variance(
        around mean: Particle.Location,
        weighted: Bool = false
    ) -> Particle.Location {
        assert(!self.isEmpty)
        
        // https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Weighted_sample_variance
        
        var totalWeight: Double = 0.0
        let uniformWeight = 1.0 / Double(self.count)
        let dimensions = mean.dimensions
        var variance = Vector(dimensions: dimensions, repeatedValue: 0.0)
        
        for particle in self {
            let weight = weighted ? particle.weight : uniformWeight
            let delta = particle.location - mean
            
            variance += weight * (delta .* delta)
            totalWeight += weight
        }
        
        return variance / totalWeight
    }
}
