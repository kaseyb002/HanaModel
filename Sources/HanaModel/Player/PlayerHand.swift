import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public var player: Player
    public var cards: [CardID]
    public var calledHana: Bool

    public init(
        player: Player,
        cards: [CardID],
        calledHana: Bool = false
    ) {
        self.player = player
        self.cards = cards
        self.calledHana = calledHana
    }
}
