internal struct AnyRandomNumberGenerator {
    var generator: RandomNumberGenerator

    init(_ generator: RandomNumberGenerator) {
        self.generator = generator
    }
}

extension AnyRandomNumberGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        return self.generator.next()
    }
}
