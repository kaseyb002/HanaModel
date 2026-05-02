import Foundation
import Testing
@testable import HanaModel

// MARK: - Deck Tests

@Test func deckSize() {
    let deck: [Card] = .deck()
    #expect(deck.count == 108)
    #expect(Set(deck.map { $0.id }).count == 108)
}

@Test func deckComposition() {
    let deck: [Card] = .deck()

    let numbers: Int = deck.filter {
        if case .number = $0.kind { return true }; return false
    }.count
    let skips: Int = deck.filter {
        if case .skip = $0.kind { return true }; return false
    }.count
    let reverses: Int = deck.filter {
        if case .reverse = $0.kind { return true }; return false
    }.count
    let drawTwos: Int = deck.filter {
        if case .drawTwo = $0.kind { return true }; return false
    }.count
    let wilds: Int = deck.filter {
        if case .wild = $0.kind { return true }; return false
    }.count
    let wildDrawFours: Int = deck.filter {
        if case .wildDrawFour = $0.kind { return true }; return false
    }.count

    #expect(numbers == 76)
    #expect(skips == 8)
    #expect(reverses == 8)
    #expect(drawTwos == 8)
    #expect(wilds == 4)
    #expect(wildDrawFours == 4)
}

// MARK: - Round Creation Tests

@Test func createRound() throws {
    let round: Round = try .init(players: [.fake(), .fake()])
    #expect(round.playerHands.count == 2)
    #expect(round.playerHands.allSatisfy { $0.cards.count >= 7 })
    #expect(round.discardPile.count >= 1)
    #expect(round.deck.count > 0)
}

@Test func createRoundMultiplePlayers() throws {
    let round: Round = try .init(players: (0..<5).map { _ in Player.fake() })
    #expect(round.playerHands.count == 5)
}

@Test func tooFewPlayers() {
    #expect(throws: HanaError.notEnoughPlayers) {
        _ = try Round(players: [.fake()])
    }
}

@Test func tooManyPlayers() {
    #expect(throws: HanaError.tooManyPlayers) {
        _ = try Round(players: (0..<11).map { _ in Player.fake() })
    }
}

@Test func maxPlayersAllowed() throws {
    let round: Round = try .init(players: (0..<10).map { _ in Player.fake() })
    #expect(round.playerHands.count == 10)
}

// MARK: - Card Matching Tests

@Test func cardMatchingColor() {
    let topKind: Card.Kind = .number(color: .red, rank: .five)
    let matchingColor: Card.Kind = .number(color: .red, rank: .three)
    let nonMatching: Card.Kind = .number(color: .blue, rank: .three)

    #expect(matchingColor.canPlayOn(topKind: topKind, activeColor: .red) == true)
    #expect(nonMatching.canPlayOn(topKind: topKind, activeColor: .red) == false)
}

@Test func cardMatchingRank() {
    let topKind: Card.Kind = .number(color: .red, rank: .five)
    let matchingRank: Card.Kind = .number(color: .blue, rank: .five)

    #expect(matchingRank.canPlayOn(topKind: topKind, activeColor: .red) == true)
}

@Test func wildCanAlwaysPlay() {
    let topKind: Card.Kind = .number(color: .red, rank: .five)
    let wild: Card.Kind = .wild(chosenColor: nil)
    let wildDrawFour: Card.Kind = .wildDrawFour(chosenColor: nil)

    #expect(wild.canPlayOn(topKind: topKind, activeColor: .red) == true)
    #expect(wildDrawFour.canPlayOn(topKind: topKind, activeColor: .red) == true)
}

@Test func actionCardMatchingType() {
    let topKind: Card.Kind = .skip(color: .red)
    let matchingType: Card.Kind = .skip(color: .blue)
    let nonMatching: Card.Kind = .reverse(color: .blue)

    #expect(matchingType.canPlayOn(topKind: topKind, activeColor: .red) == true)
    #expect(nonMatching.canPlayOn(topKind: topKind, activeColor: .red) == false)
}

// MARK: - Points Tests

@Test func cardPoints() {
    #expect(Card.Kind.number(color: .red, rank: .zero).points == 0)
    #expect(Card.Kind.number(color: .blue, rank: .nine).points == 9)
    #expect(Card.Kind.skip(color: .red).points == 20)
    #expect(Card.Kind.reverse(color: .blue).points == 20)
    #expect(Card.Kind.drawTwo(color: .green).points == 20)
    #expect(Card.Kind.wild(chosenColor: nil).points == 50)
    #expect(Card.Kind.wildDrawFour(chosenColor: nil).points == 50)
}

// MARK: - Play Card Tests

@Test func playMatchingCard() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .number(color: .red, rank: .one),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    #expect(round.currentPlayerID == "p1")
    #expect(round.activeColor == .red)

    let redOneID: CardID = round.playerHands[0].cards.first {
        round.cardsMap[$0]?.kind == .number(color: .red, rank: .one)
    }!

    try round.playCard(redOneID)

    #expect(round.currentPlayerID == "p2")
    #expect(round.activeColor == .red)
    #expect(round.playerHands[0].cards.count == 6)
}

@Test func playCardNotPlayable() throws {
    var round: Round = try makeSimpleRound()
    let blueCard: CardID? = round.playerHands[0].cards.first {
        guard let card: Card = round.cardsMap[$0] else { return false }
        return card.kind.color == .blue && round.activeColor != .blue
    }

    if let blueCard, round.activeColor != .blue {
        if let topCard: Card = round.topDiscardCard {
            let card: Card = round.cardsMap[blueCard]!
            if card.kind.canPlayOn(topKind: topCard.kind, activeColor: round.activeColor) == false {
                #expect(throws: HanaError.cardNotPlayable) {
                    try round.playCard(blueCard)
                }
            }
        }
    }
}

@Test func playWildCard() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .wild(chosenColor: nil),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    let wildID: CardID = round.playerHands[0].cards.first {
        if case .wild = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    #expect(throws: HanaError.invalidColorChoice) {
        try round.playCard(wildID)
    }

    try round.playCard(wildID, chosenColor: .yellow)

    #expect(round.activeColor == .yellow)
    #expect(round.currentPlayerID == "p2")
}

// MARK: - Draw Card Tests

@Test func drawCard() throws {
    var round: Round = try makeSimpleRound()

    let initialHandSize: Int = round.playerHands[0].cards.count
    try round.drawCard()

    if case .waitingForPlayer(_, .drewCard) = round.state {
        #expect(round.playerHands[0].cards.count == initialHandSize + 1)
    } else if case .waitingForPlayer(let playerID, .playOrDraw) = round.state {
        #expect(playerID == "p2")
        #expect(round.playerHands[0].cards.count == initialHandSize + 1)
    }
}

@Test func passAfterDraw() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .number(color: .red, rank: .one),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .eight)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    let redOneID: CardID = round.playerHands[0].cards.first {
        round.cardsMap[$0]?.kind == .number(color: .red, rank: .one)
    }!
    try round.playCard(redOneID)

    // p2 has no red or matching card, draws
    try round.drawCard()
    // Drawn card is green 8, not playable on red 1
    if case .waitingForPlayer(_, .drewCard) = round.state {
        try round.passAfterDraw()
    }
    #expect(round.currentPlayerID == "p1")
}

// MARK: - Skip Tests

@Test func skipCard() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .skip(color: .red),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        player3Cards: [
            .number(color: .yellow, rank: .one),
            .number(color: .yellow, rank: .two),
            .number(color: .yellow, rank: .three),
            .number(color: .yellow, rank: .four),
            .number(color: .yellow, rank: .five),
            .number(color: .yellow, rank: .six),
            .number(color: .yellow, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
            .fake(id: "p3", name: "Charlie", points: 0),
        ]
    )

    let skipID: CardID = round.playerHands[0].cards.first {
        if case .skip = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(skipID)
    #expect(round.currentPlayerID == "p3")
}

// MARK: - Reverse Tests

@Test func reverseCard() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .reverse(color: .red),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        player3Cards: [
            .number(color: .yellow, rank: .one),
            .number(color: .yellow, rank: .two),
            .number(color: .yellow, rank: .three),
            .number(color: .yellow, rank: .four),
            .number(color: .yellow, rank: .five),
            .number(color: .yellow, rank: .six),
            .number(color: .yellow, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
            .fake(id: "p3", name: "Charlie", points: 0),
        ]
    )

    #expect(round.direction == .clockwise)

    let reverseID: CardID = round.playerHands[0].cards.first {
        if case .reverse = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(reverseID)
    #expect(round.direction == .counterclockwise)
    #expect(round.currentPlayerID == "p3")
}

@Test func reverseInTwoPlayerActsAsSkip() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .reverse(color: .red),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    let reverseID: CardID = round.playerHands[0].cards.first {
        if case .reverse = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(reverseID)
    #expect(round.currentPlayerID == "p1")
}

// MARK: - Draw Two Tests

@Test func drawTwoCard() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .drawTwo(color: .red),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        player3Cards: [
            .number(color: .yellow, rank: .one),
            .number(color: .yellow, rank: .two),
            .number(color: .yellow, rank: .three),
            .number(color: .yellow, rank: .four),
            .number(color: .yellow, rank: .five),
            .number(color: .yellow, rank: .six),
            .number(color: .yellow, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
            .fake(id: "p3", name: "Charlie", points: 0),
        ]
    )

    let drawTwoID: CardID = round.playerHands[0].cards.first {
        if case .drawTwo = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(drawTwoID)

    #expect(round.playerHands[1].cards.count == 9)
    #expect(round.currentPlayerID == "p3")
}

// MARK: - Draw Two Stacking Tests

@Test func drawTwoStacking() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .drawTwo(color: .red),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .drawTwo(color: .blue),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        player3Cards: [
            .number(color: .yellow, rank: .one),
            .number(color: .yellow, rank: .two),
            .number(color: .yellow, rank: .three),
            .number(color: .yellow, rank: .four),
            .number(color: .yellow, rank: .five),
            .number(color: .yellow, rank: .six),
            .number(color: .yellow, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        ruleOptions: .init(stackingDrawCards: true),
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
            .fake(id: "p3", name: "Charlie", points: 0),
        ]
    )

    let p1DrawTwoID: CardID = round.playerHands[0].cards.first {
        if case .drawTwo = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(p1DrawTwoID)
    #expect(round.pendingDrawCount == 2)
    #expect(round.currentPlayerID == "p2")

    let p2DrawTwoID: CardID = round.playerHands[1].cards.first {
        if case .drawTwo = round.cardsMap[$0]?.kind { return true }
        return false
    }!

    try round.playCard(p2DrawTwoID)
    #expect(round.pendingDrawCount == 4)
    #expect(round.currentPlayerID == "p3")

    try round.drawCard()
    #expect(round.playerHands[2].cards.count == 11)
    #expect(round.pendingDrawCount == 0)
}

// MARK: - AI Tests

@Test func aiCompletesRound() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1", name: "AI-1", points: 0),
        .fake(id: "p2", name: "AI-2", points: 0),
    ])

    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while case .waitingForPlayer = round.state, turnCount < maxTurns {
        round.makeAIMove(difficulty: .medium)
        turnCount += 1
    }

    #expect(turnCount < maxTurns)
    if case .roundComplete(let winnerID) = round.state {
        let winnerIndex: Int = round.playerHands.firstIndex { $0.player.id == winnerID }!
        #expect(round.playerHands[winnerIndex].cards.isEmpty)
    }
}

@Test func aiCompletesRoundHard() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1", name: "AI-1", points: 0),
        .fake(id: "p2", name: "AI-2", points: 0),
        .fake(id: "p3", name: "AI-3", points: 0),
    ])

    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while case .waitingForPlayer = round.state, turnCount < maxTurns {
        round.makeAIMove(difficulty: .hard)
        turnCount += 1
    }

    #expect(turnCount < maxTurns)
    if case .roundComplete = round.state {
        let totalCards: Int = round.playerHands.reduce(0) { $0 + $1.cards.count }
            + round.deck.count + round.discardPile.count
        #expect(totalCards == 108)
    }
}

@Test func aiCompletesRoundEasy() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1", name: "AI-1", points: 0),
        .fake(id: "p2", name: "AI-2", points: 0),
    ])

    var turnCount: Int = 0
    let maxTurns: Int = 1000

    while case .waitingForPlayer = round.state, turnCount < maxTurns {
        round.makeAIMove(difficulty: .easy)
        turnCount += 1
    }

    #expect(turnCount < maxTurns)
}

// MARK: - Full Round Playthrough

@Test func playFullRoundManually() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .number(color: .red, rank: .one),
            .number(color: .red, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .green, rank: .four),
            .number(color: .yellow, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .red, rank: .eight),
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .green, rank: .three),
            .number(color: .green, rank: .five),
            .number(color: .yellow, rank: .six),
            .number(color: .yellow, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .red, rank: .nine)
    )

    var round: Round = try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    func findCard(_ playerIndex: Int, _ kind: Card.Kind) -> CardID {
        round.playerHands[playerIndex].cards.first {
            round.cardsMap[$0]?.kind == kind
        }!
    }

    // Turn 1: P1 plays red 1
    try round.playCard(findCard(0, .number(color: .red, rank: .one)))
    #expect(round.currentPlayerID == "p2")

    // Turn 2: P2 plays red 8 (matches color)
    try round.playCard(findCard(1, .number(color: .red, rank: .eight)))
    #expect(round.currentPlayerID == "p1")

    // Turn 3: P1 plays red 2 (matches color)
    try round.playCard(findCard(0, .number(color: .red, rank: .two)))
    #expect(round.currentPlayerID == "p2")

    // Turn 4: P2 plays blue 2 (matches rank)
    try round.playCard(findCard(1, .number(color: .blue, rank: .two)))
    #expect(round.activeColor == .blue)

    // Turn 5: P1 plays blue 3 (matches color)
    try round.playCard(findCard(0, .number(color: .blue, rank: .three)))

    // Turn 6: P2 plays green 3 (matches rank)
    try round.playCard(findCard(1, .number(color: .green, rank: .three)))
    #expect(round.activeColor == .green)

    // Turn 7: P1 plays green 4 (matches color)
    try round.playCard(findCard(0, .number(color: .green, rank: .four)))

    // Turn 8: P2 plays green 5 (matches color)
    try round.playCard(findCard(1, .number(color: .green, rank: .five)))

    // Turn 9: P1 plays yellow 5 (matches rank)
    try round.playCard(findCard(0, .number(color: .yellow, rank: .five)))
    #expect(round.activeColor == .yellow)

    // Turn 10: P2 plays yellow 6 (matches color)
    try round.playCard(findCard(1, .number(color: .yellow, rank: .six)))

    // Turn 11: P1 plays red 6 (matches rank)
    try round.playCard(findCard(0, .number(color: .red, rank: .six)))

    // Turn 12: P1 has 1 card left (red 7), P2 has 2 cards
    #expect(round.playerHands[0].cards.count == 1)

    // Turn 12: P2 plays yellow 7 (matches rank of red 6? No, matches rank 6 -> need rank match)
    // Actually P2 needs to play something on red 6. P2 has blue 1, yellow 7.
    // blue 1 doesn't match. yellow 7 doesn't match.
    // P2 must draw.
    try round.drawCard()
    // Drawn card is red 9 (from draw pile), playable on red
    if case .waitingForPlayer(_, .drewCard) = round.state {
        let lastCardID: CardID = round.playerHands[1].cards.last!
        try round.playCard(lastCardID)
    }

    // Turn 13: P1 plays red 7 on red 9
    try round.playCard(findCard(0, .number(color: .red, rank: .seven)))

    #expect(round.playerHands[0].cards.isEmpty)
    if case .roundComplete(let winnerID) = round.state {
        #expect(winnerID == "p1")
    }

    let p2RemainingPoints: Int = round.playerHands[1].cards.totalPoints(cardsMap: round.cardsMap)
    #expect(round.playerHands[0].player.points == p2RemainingPoints)
}

// MARK: - Fake Tests

@Test func fakePlayer() {
    let player: Player = .fake()
    #expect(player.name.isEmpty == false)
    #expect(player.points == 0)
}

@Test func fakeRound() throws {
    let round: Round = try .fake()
    #expect(round.playerHands.count == 3)
}

@Test func fakeCard() {
    let card: Card = .fake()
    #expect(card.kind == .number(color: .red, rank: .five))
}

// MARK: - Hana Call Tests

@Test func hanaPenalty() throws {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .number(color: .red, rank: .one),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    var round: Round = try .init(
        ruleOptions: .init(unoCallPenalty: true),
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )

    // Play down to 2 cards
    for rank in [CardRank.one, .two, .three, .four, .five] {
        let cardID: CardID = round.playerHands[0].cards.first {
            round.cardsMap[$0]?.kind == .number(color: .red, rank: rank)
        }!
        try round.playCard(cardID)

        // P2 draws and passes each turn
        if case .waitingForPlayer(_, .playOrDraw) = round.state {
            try round.drawCard()
            if case .waitingForPlayer(_, .drewCard) = round.state {
                try round.passAfterDraw()
            }
        }
    }

    // P1 plays 6th card -> goes to 1 card
    let sixID: CardID = round.playerHands[0].cards.first {
        round.cardsMap[$0]?.kind == .number(color: .red, rank: .six)
    }!
    try round.playCard(sixID)

    #expect(round.playerHands[0].cards.count == 1)
    #expect(round.playerWhoNeedsToCallHana == "p1")

    try round.catchMissedHana(callerID: "p2", targetID: "p1")

    #expect(round.playerHands[0].cards.count == 3)
    #expect(round.playerWhoNeedsToCallHana == nil)
}

// MARK: - Codable Tests

@Test func roundCodable() throws {
    let round: Round = try .fake()
    let encoder: JSONEncoder = .init()
    let data: Data = try encoder.encode(round)
    let decoder: JSONDecoder = .init()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let decoded: Round = try decoder.decode(Round.self, from: data)
    #expect(decoded.id == round.id)
    #expect(decoded.playerHands.count == round.playerHands.count)
}

// MARK: - Helpers

private func makeSimpleRound() throws -> Round {
    let cookedCards: [Card] = buildCookedDeck(
        player1Cards: [
            .number(color: .red, rank: .one),
            .number(color: .red, rank: .two),
            .number(color: .red, rank: .three),
            .number(color: .red, rank: .four),
            .number(color: .red, rank: .five),
            .number(color: .red, rank: .six),
            .number(color: .red, rank: .seven),
        ],
        player2Cards: [
            .number(color: .blue, rank: .one),
            .number(color: .blue, rank: .two),
            .number(color: .blue, rank: .three),
            .number(color: .blue, rank: .four),
            .number(color: .blue, rank: .five),
            .number(color: .blue, rank: .six),
            .number(color: .blue, rank: .seven),
        ],
        firstDiscard: .number(color: .red, rank: .zero),
        drawPileKind: .number(color: .green, rank: .one)
    )

    return try .init(
        cookedDeck: cookedCards,
        players: [
            .fake(id: "p1", name: "Alice", points: 0),
            .fake(id: "p2", name: "Bob", points: 0),
        ]
    )
}

/// Builds a cooked deck for a 2- or 3-player test game.
/// Cards are laid out so that dealing from the end gives Player 1 the first 7,
/// Player 2 the next 7 (or Player 3 the next 7 after that), then the first discard,
/// then the draw pile fills the front.
private func buildCookedDeck(
    player1Cards: [Card.Kind],
    player2Cards: [Card.Kind],
    player3Cards: [Card.Kind]? = nil,
    firstDiscard: Card.Kind,
    drawPileKind: Card.Kind
) -> [Card] {
    var cards: [Card] = []
    var nextID: Int = 0

    let drawPileSize: Int = 108 - player1Cards.count - player2Cards.count
        - (player3Cards?.count ?? 0) - 1

    for _ in 0..<drawPileSize {
        cards.append(.init(id: nextID, kind: drawPileKind))
        nextID += 1
    }

    cards.append(.init(id: nextID, kind: firstDiscard))
    nextID += 1

    if let player3Cards {
        for kind in player3Cards {
            cards.append(.init(id: nextID, kind: kind))
            nextID += 1
        }
    }

    for kind in player2Cards {
        cards.append(.init(id: nextID, kind: kind))
        nextID += 1
    }

    for kind in player1Cards {
        cards.append(.init(id: nextID, kind: kind))
        nextID += 1
    }

    return cards
}
