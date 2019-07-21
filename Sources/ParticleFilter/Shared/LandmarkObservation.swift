import Foundation

public struct LandmarkObservation<Measurement> {
    public var landmark: Landmark
    public var measurement: Measurement
    
    public init(landmark: Landmark, measurement: Measurement) {
        self.landmark = landmark
        self.measurement = measurement
    }
}
