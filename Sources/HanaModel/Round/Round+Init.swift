import Foundation

extension Round {
    public static let defaultHandSize: Int = 7

    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        ruleOptions: RuleOptions = .classic,
        cookedDeck: [Card]? = nil,
        players: [Player]
    ) throws {
        guard players.count >= 2 else {
            throw HanaError.notEnoughPlayers
        }
        guard players.count <= 10 else {
            throw HanaError.tooManyPlayers
        }

        self.id = id
        self.started = started
        self.ruleOptions = ruleOptions
        self.log = .init()
        self.ended = nil
        self.playerWhoNeedsToCallHana = nil
        self.pendingDrawCount = 0
        self.direction = .clockwise

        var allCards: [Card] = cookedDeck ?? [Card].deck().shuffled()
        self.cardsMap = Dictionary(uniqueKeysWithValues: allCards.map { ($0.id, $0) })

        self.playerHands = Self.dealCards(to: players, deck: &allCards)

        var firstCard: Card = allCards.removeLast()
        if cookedDeck == nil {
            while case .wildDrawFour = firstCard.kind {
                allCards.insert(firstCard, at: 0)
                allCards.shuffle()
                firstCard = allCards.removeLast()
            }
        }

        self.deck = allCards.map(\.id)
        self.discardPile = [firstCard.id]
        self.activeColor = firstCard.kind.color ?? CardColor.allCases.randomElement()!

        var firstPlayerIndex: Int = 0

        switch firstCard.kind {
        case .reverse:
            self.direction = .counterclockwise

        case .skip:
            firstPlayerIndex = 1 % players.count

        case .drawTwo:
            if ruleOptions.stackingDrawCards {
                self.pendingDrawCount = 2
            } else {
                var deckIDs: [CardID] = self.deck
                for _ in 0..<2 {
                    if deckIDs.isEmpty == false {
                        self.playerHands[0].cards.append(deckIDs.removeLast())
                    }
                }
                self.deck = deckIDs
                firstPlayerIndex = 1 % players.count
            }

        default:
            break
        }

        self.state = .waitingForPlayer(
            playerId: players[firstPlayerIndex].id,
            phase: .playOrDraw
        )
    }

    private static func dealCards(
        to players: [Player],
        deck: inout [Card]
    ) -> [PlayerHand] {
        var playerHands: [PlayerHand] = []
        for player in players {
            let playerCards: [Card] = Array(deck.suffix(defaultHandSize))
            deck.removeLast(defaultHandSize)
            let playerHand: PlayerHand = .init(
                player: player,
                cards: playerCards.map(\.id)
            )
            playerHands.append(playerHand)
        }
        return playerHands
    }
}
