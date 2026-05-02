import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date
    public let ruleOptions: RuleOptions

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var deck: [CardID]
    public internal(set) var discardPile: [CardID]
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var direction: Direction = .clockwise
    public internal(set) var activeColor: CardColor = .red
    public internal(set) var pendingDrawCount: Int = 0
    public internal(set) var playerWhoNeedsToCallHana: PlayerID?

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public enum Direction: String, Equatable, Codable, Sendable {
        case clockwise
        case counterclockwise

        public var reversed: Direction {
            switch self {
            case .clockwise: .counterclockwise
            case .counterclockwise: .clockwise
            }
        }
    }

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayer(playerId: PlayerID, phase: TurnPhase)
        case roundComplete(winnerId: PlayerID)

        public enum TurnPhase: String, Equatable, Codable, Sendable {
            case playOrDraw
            case drewCard
        }

        public var logValue: String {
            switch self {
            case .waitingForPlayer(let playerID, let phase):
                "Waiting for \(playerID) (\(phase.rawValue))"
            case .roundComplete(let winnerID):
                "Round complete — winner: \(winnerID)"
            }
        }
    }
}
