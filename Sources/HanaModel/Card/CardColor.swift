import Foundation

public enum CardColor: String, Equatable, CaseIterable, Codable, Sendable {
    case red
    case blue
    case green
    case yellow

    public var displayableName: String {
        switch self {
        case .red: "Red"
        case .blue: "Blue"
        case .green: "Green"
        case .yellow: "Yellow"
        }
    }

    public var logValue: String {
        switch self {
        case .red: "🔴"
        case .blue: "🔵"
        case .green: "🟢"
        case .yellow: "🟡"
        }
    }
}
