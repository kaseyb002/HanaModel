import Foundation

extension Round {
    public static func fake(
        id: String = UUID().uuidString,
        started: Date = .init(),
        ruleOptions: RuleOptions = .classic,
        cookedDeck: [Card]? = nil,
        players: [Player] = [
            .fake(),
            .fake(),
            .fake(),
        ]
    ) throws -> Round {
        try self.init(
            id: id,
            started: started,
            ruleOptions: ruleOptions,
            cookedDeck: cookedDeck,
            players: players
        )
    }
}
