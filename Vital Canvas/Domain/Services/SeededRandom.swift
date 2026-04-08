import Foundation

struct SeededRandom {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(bitPattern: Int64(seed &+ 1))
        _ = next()
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next()) / Double(UInt64.max)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + nextDouble() * (range.upperBound - range.lowerBound)
    }
}
