import Foundation

internal struct NormalCumulativeDistributionFunction {
    internal func evaluate(
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
