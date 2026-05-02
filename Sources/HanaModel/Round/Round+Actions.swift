import Foundation

// MARK: - Player Actions

extension Round {
    public mutating func playCard(
        _ cardID: CardID,
        chosenColor: CardColor? = nil,
        swapWithPlayerID: PlayerID? = nil
    ) throws {
        guard case .waitingForPlayer(let currentPlayerID, let phase) = state else {
            throw HanaError.roundAlreadyComplete
        }
        guard phase == .playOrDraw || phase == .drewCard else {
            throw HanaError.notYourTurn
        }
        guard let playerIndex: Int = playerHandIndex(for: currentPlayerID) else {
            throw HanaError.playerNotFound
        }
        guard playerHands[playerIndex].cards.contains(cardID) else {
            throw HanaError.cardNotInHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw HanaError.cardNotInHand
        }

        if phase == .drewCard {
            guard cardID == playerHands[playerIndex].cards.last else {
                throw HanaError.canOnlyPlayDrawnCard
            }
        }

        guard let topCard: Card = topDiscardCard else {
            throw HanaError.cardNotInHand
        }

        if pendingDrawCount > 0 {
            if ruleOptions.stackingDrawCards {
                let canStack: Bool
                switch (topCard.kind, card.kind) {
                case (.drawTwo, .drawTwo): canStack = true
                case (.wildDrawFour, .wildDrawFour): canStack = true
                default: canStack = false
                }
                guard canStack else {
                    throw HanaError.mustRespondToDrawPenalty
                }
            } else {
                throw HanaError.mustRespondToDrawPenalty
            }
        } else {
            guard card.kind.canPlayOn(topKind: topCard.kind, activeColor: activeColor) else {
                throw HanaError.cardNotPlayable
            }

            if case .wildDrawFour = card.kind,
               ruleOptions.allowWildDrawFourAnytime == false {
                let hasMatchingColor: Bool = playerHands[playerIndex].cards.contains { id in
                    guard let c: Card = cardsMap[id] else { return false }
                    return c.kind.color == activeColor && c.id != cardID
                }
                if hasMatchingColor {
                    throw HanaError.wildDrawFourNotAllowed
                }
            }
        }

        if card.kind.isWild {
            guard chosenColor != nil else {
                throw HanaError.invalidColorChoice
            }
        }

        if ruleOptions.sevenZero, case .number(_, .seven) = card.kind {
            guard let swapTarget: PlayerID = swapWithPlayerID else {
                throw HanaError.mustSpecifySwapTarget
            }
            guard swapTarget != currentPlayerID else {
                throw HanaError.cannotSwapWithSelf
            }
            guard playerHandIndex(for: swapTarget) != nil else {
                throw HanaError.playerNotFound
            }
        }

        playerWhoNeedsToCallHana = nil

        playerHands[playerIndex].cards.removeAll { $0 == cardID }

        if case .wild = card.kind, let chosenColor {
            cardsMap[cardID]?.kind = .wild(chosenColor: chosenColor)
        } else if case .wildDrawFour = card.kind, let chosenColor {
            cardsMap[cardID]?.kind = .wildDrawFour(chosenColor: chosenColor)
        }

        discardPile.append(cardID)

        if let chosenColor {
            activeColor = chosenColor
        } else if let cardColor: CardColor = card.kind.color {
            activeColor = cardColor
        }

        log.addAction(.init(
            playerID: currentPlayerID,
            decision: .playCard(cardId: cardID)
        ))

        if playerHands[playerIndex].cards.isEmpty {
            applyFinalCardEffects(card: cardsMap[cardID] ?? card, currentPlayerIndex: playerIndex)
            state = .roundComplete(winnerId: currentPlayerID)
            calculatePoints(winnerIndex: playerIndex)
            ended = .init()
            return
        }

        if ruleOptions.unoCallPenalty && playerHands[playerIndex].cards.count == 1 {
            playerWhoNeedsToCallHana = currentPlayerID
            playerHands[playerIndex].calledHana = false
        }

        if ruleOptions.sevenZero {
            if case .number(_, .seven) = card.kind, let swapWithPlayerID {
                swapPlayerHands(playerIndex, with: swapWithPlayerID)
            } else if case .number(_, .zero) = card.kind {
                rotateHands()
            }
        }

        applyCardEffects(card: cardsMap[cardID] ?? card, currentPlayerIndex: playerIndex)
    }

    public mutating func drawCard() throws {
        guard case .waitingForPlayer(let currentPlayerID, .playOrDraw) = state else {
            throw HanaError.notInDrawPhase
        }
        guard let playerIndex: Int = playerHandIndex(for: currentPlayerID) else {
            throw HanaError.playerNotFound
        }

        playerWhoNeedsToCallHana = nil

        if pendingDrawCount > 0 {
            applyDrawPenalty(to: playerIndex)
            log.addAction(.init(
                playerID: currentPlayerID,
                decision: .drawCards(count: pendingDrawCount > 0 ? pendingDrawCount : 2)
            ))
            advancePlayer(from: playerIndex)
            return
        }

        var drawnCount: Int = 0
        var lastDrawnPlayable: Bool = false

        repeat {
            guard let drawnCardID: CardID = drawOneCard(for: playerIndex) else {
                endRoundDeckEmpty()
                return
            }
            drawnCount += 1

            if let drawnCard: Card = cardsMap[drawnCardID],
               let topCard: Card = topDiscardCard {
                lastDrawnPlayable = drawnCard.kind.canPlayOn(
                    topKind: topCard.kind,
                    activeColor: activeColor
                )
            }
        } while ruleOptions.drawUntilPlayable && lastDrawnPlayable == false

        log.addAction(.init(
            playerID: currentPlayerID,
            decision: .drawCards(count: drawnCount)
        ))

        if lastDrawnPlayable {
            state = .waitingForPlayer(playerId: currentPlayerID, phase: .drewCard)
        } else {
            advancePlayer(from: playerIndex)
        }
    }

    public mutating func passAfterDraw() throws {
        guard case .waitingForPlayer(let currentPlayerID, .drewCard) = state else {
            throw HanaError.notInDrawPhase
        }
        guard let playerIndex: Int = playerHandIndex(for: currentPlayerID) else {
            throw HanaError.playerNotFound
        }

        if ruleOptions.forcePlayDrawnCard {
            if let lastCardID: CardID = playerHands[playerIndex].cards.last,
               let lastCard: Card = cardsMap[lastCardID],
               let topCard: Card = topDiscardCard,
               lastCard.kind.canPlayOn(topKind: topCard.kind, activeColor: activeColor) {
                throw HanaError.cannotPassMustPlay
            }
        }

        log.addAction(.init(
            playerID: currentPlayerID,
            decision: .pass
        ))

        advancePlayer(from: playerIndex)
    }

    public mutating func callHana(playerID: PlayerID) throws {
        guard ruleOptions.unoCallPenalty else {
            throw HanaError.hanaCallNotNeeded
        }
        guard playerWhoNeedsToCallHana == playerID else {
            throw HanaError.hanaCallNotNeeded
        }
        guard let playerIndex: Int = playerHandIndex(for: playerID) else {
            throw HanaError.playerNotFound
        }

        playerHands[playerIndex].calledHana = true
        playerWhoNeedsToCallHana = nil

        log.addAction(.init(
            playerID: playerID,
            decision: .callHana
        ))
    }

    public mutating func catchMissedHana(callerID: PlayerID, targetID: PlayerID) throws {
        guard ruleOptions.unoCallPenalty else {
            throw HanaError.hanaCallNotNeeded
        }
        guard callerID != targetID else {
            throw HanaError.cannotCatchOwnHana
        }
        guard playerWhoNeedsToCallHana == targetID else {
            throw HanaError.noMissedHanaToCatch
        }
        guard let targetIndex: Int = playerHandIndex(for: targetID) else {
            throw HanaError.playerNotFound
        }

        drawCardsFromDeck(count: 2, for: targetIndex)
        playerWhoNeedsToCallHana = nil

        log.addAction(.init(
            playerID: callerID,
            decision: .catchHana(targetPlayerId: targetID)
        ))
    }

    public mutating func jumpIn(
        playerID: PlayerID,
        cardID: CardID,
        chosenColor: CardColor? = nil
    ) throws {
        guard ruleOptions.jumpIn else {
            throw HanaError.jumpInNotEnabled
        }
        guard case .waitingForPlayer(let currentPlayerID, _) = state else {
            throw HanaError.roundAlreadyComplete
        }
        guard playerID != currentPlayerID else {
            throw HanaError.invalidJumpIn
        }
        guard let playerIndex: Int = playerHandIndex(for: playerID) else {
            throw HanaError.playerNotFound
        }
        guard playerHands[playerIndex].cards.contains(cardID) else {
            throw HanaError.cardNotInHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw HanaError.cardNotInHand
        }
        guard let topCard: Card = topDiscardCard else {
            throw HanaError.invalidJumpIn
        }

        let isExactMatch: Bool = Self.isExactMatch(card.kind, topCard.kind)
        guard isExactMatch else {
            throw HanaError.invalidJumpIn
        }

        playerWhoNeedsToCallHana = nil
        playerHands[playerIndex].cards.removeAll { $0 == cardID }

        if card.kind.isWild, let chosenColor {
            if case .wild = card.kind {
                cardsMap[cardID]?.kind = .wild(chosenColor: chosenColor)
            } else {
                cardsMap[cardID]?.kind = .wildDrawFour(chosenColor: chosenColor)
            }
            activeColor = chosenColor
        } else if let color: CardColor = card.kind.color {
            activeColor = color
        }

        discardPile.append(cardID)

        log.addAction(.init(
            playerID: playerID,
            decision: .jumpIn(cardId: cardID)
        ))

        if playerHands[playerIndex].cards.isEmpty {
            applyFinalCardEffects(card: cardsMap[cardID] ?? card, currentPlayerIndex: playerIndex)
            state = .roundComplete(winnerId: playerID)
            calculatePoints(winnerIndex: playerIndex)
            ended = .init()
            return
        }

        if ruleOptions.unoCallPenalty && playerHands[playerIndex].cards.count == 1 {
            playerWhoNeedsToCallHana = playerID
            playerHands[playerIndex].calledHana = false
        }

        applyCardEffects(card: cardsMap[cardID] ?? card, currentPlayerIndex: playerIndex)
    }
}

// MARK: - Internal Helpers

extension Round {
    static func isExactMatch(_ a: Card.Kind, _ b: Card.Kind) -> Bool {
        switch (a, b) {
        case (.number(let c1, let r1), .number(let c2, let r2)):
            c1 == c2 && r1 == r2
        case (.skip(let c1), .skip(let c2)):
            c1 == c2
        case (.reverse(let c1), .reverse(let c2)):
            c1 == c2
        case (.drawTwo(let c1), .drawTwo(let c2)):
            c1 == c2
        case (.wild, .wild):
            true
        case (.wildDrawFour, .wildDrawFour):
            true
        default:
            false
        }
    }

    mutating func applyCardEffects(card: Card, currentPlayerIndex: Int) {
        switch card.kind {
        case .reverse:
            if playerHands.count == 2 {
                advancePlayer(from: currentPlayerIndex, skip: 1)
            } else {
                direction = direction.reversed
                advancePlayer(from: currentPlayerIndex)
            }

        case .skip:
            advancePlayer(from: currentPlayerIndex, skip: 1)

        case .drawTwo:
            pendingDrawCount += 2
            if ruleOptions.stackingDrawCards {
                advancePlayer(from: currentPlayerIndex)
            } else {
                let nextIndex: Int = nextPlayerIndex(from: currentPlayerIndex)
                applyDrawPenalty(to: nextIndex)
                advancePlayer(from: nextIndex)
            }

        case .wildDrawFour:
            pendingDrawCount += 4
            if ruleOptions.stackingDrawCards {
                advancePlayer(from: currentPlayerIndex)
            } else {
                let nextIndex: Int = nextPlayerIndex(from: currentPlayerIndex)
                applyDrawPenalty(to: nextIndex)
                advancePlayer(from: nextIndex)
            }

        default:
            advancePlayer(from: currentPlayerIndex)
        }
    }

    mutating func applyFinalCardEffects(card: Card, currentPlayerIndex: Int) {
        switch card.kind {
        case .drawTwo:
            let nextIndex: Int = nextPlayerIndex(from: currentPlayerIndex)
            drawCardsFromDeck(count: 2, for: nextIndex)

        case .wildDrawFour:
            let nextIndex: Int = nextPlayerIndex(from: currentPlayerIndex)
            drawCardsFromDeck(count: 4, for: nextIndex)

        default:
            break
        }
    }

    mutating func advancePlayer(from currentIndex: Int, skip: Int = 0) {
        var nextIndex: Int = currentIndex
        for _ in 0...skip {
            nextIndex = nextPlayerIndex(from: nextIndex)
        }
        state = .waitingForPlayer(
            playerId: playerHands[nextIndex].player.id,
            phase: .playOrDraw
        )
    }

    mutating func drawOneCard(for playerIndex: Int) -> CardID? {
        if deck.isEmpty {
            reshuffleDeck()
        }
        guard deck.isEmpty == false else { return nil }
        let cardID: CardID = deck.removeLast()
        playerHands[playerIndex].cards.append(cardID)
        return cardID
    }

    mutating func drawCardsFromDeck(count: Int, for playerIndex: Int) {
        for _ in 0..<count {
            _ = drawOneCard(for: playerIndex)
        }
    }

    mutating func applyDrawPenalty(to playerIndex: Int) {
        drawCardsFromDeck(count: pendingDrawCount, for: playerIndex)
        pendingDrawCount = 0
    }

    mutating func reshuffleDeck() {
        guard discardPile.count > 1 else { return }
        let topCardID: CardID = discardPile.removeLast()
        deck = discardPile.shuffled()
        for cardID in deck {
            if case .wild = cardsMap[cardID]?.kind {
                cardsMap[cardID]?.kind = .wild(chosenColor: nil)
            } else if case .wildDrawFour = cardsMap[cardID]?.kind {
                cardsMap[cardID]?.kind = .wildDrawFour(chosenColor: nil)
            }
        }
        discardPile = [topCardID]
    }

    mutating func swapPlayerHands(_ playerIndex1: Int, with targetPlayerID: PlayerID) {
        guard let playerIndex2: Int = playerHandIndex(for: targetPlayerID) else { return }
        let temp: [CardID] = playerHands[playerIndex1].cards
        playerHands[playerIndex1].cards = playerHands[playerIndex2].cards
        playerHands[playerIndex2].cards = temp
        playerHands[playerIndex1].calledHana = false
        playerHands[playerIndex2].calledHana = false
    }

    mutating func rotateHands() {
        var hands: [[CardID]] = playerHands.map(\.cards)
        switch direction {
        case .clockwise:
            let last: [CardID] = hands.removeLast()
            hands.insert(last, at: 0)
        case .counterclockwise:
            let first: [CardID] = hands.removeFirst()
            hands.append(first)
        }
        for i in 0..<playerHands.count {
            playerHands[i].cards = hands[i]
            playerHands[i].calledHana = false
        }
    }

    mutating func endRoundDeckEmpty() {
        if let winner: PlayerHand = playerHands.min(by: { $0.cards.count < $1.cards.count }) {
            state = .roundComplete(winnerId: winner.player.id)
            calculatePoints(winnerIndex: playerHands.firstIndex { $0.player.id == winner.player.id } ?? 0)
        }
        ended = .init()
    }
}
