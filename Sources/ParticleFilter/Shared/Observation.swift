import simd

public struct Observation: Equatable {
    public typealias Scalar = Double
    public typealias Vector = SIMD3<Double>

    public var xyz: Vector
    public var measurement: Scalar
}
