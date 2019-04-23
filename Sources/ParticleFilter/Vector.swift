import simd

public typealias Float3 = SIMD3<Float>
public typealias Double3 = SIMD3<Double>

extension Float3 {
    public func distance(to other: Float3) -> Scalar {
        return simd_length(self - other)
    }
}

extension Double3 {
    public func distance(to other: Double3) -> Scalar {
        return simd_length(self - other)
    }
}
