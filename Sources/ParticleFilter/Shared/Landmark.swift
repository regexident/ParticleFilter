import Foundation

import Surge

public struct Landmark {
    public typealias Location = Vector<Double>
    public typealias Identifier = UUID
    
    public var location: Location
    public let identifier: Identifier
    
    public init(location: Location, identifier: Identifier = .init()) {
        self.location = location
        self.identifier = identifier
    }
}
