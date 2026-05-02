import Foundation

public enum CardRank: Int, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case zero = 0
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9

    public static func < (lhs: CardRank, rhs: CardRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayableName: String {
        "\(rawValue)"
    }
}
