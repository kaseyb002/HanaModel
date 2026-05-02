import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        cards: [CardID] = [],
        calledHana: Bool = false
    ) -> PlayerHand {
        .init(
            player: player,
            cards: cards,
            calledHana: calledHana
        )
    }
}
