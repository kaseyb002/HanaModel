import Foundation

extension Round {
    public enum AIDifficulty: String, Equatable, Codable, Sendable {
        case easy
        case medium
        case hard
    }

    public mutating func makeAIMove(difficulty: AIDifficulty) {
        guard case .waitingForPlayer(let currentPlayerID, let phase) = state else {
            return
        }

        switch phase {
        case .playOrDraw:
            makeAIPlayOrDraw(playerID: currentPlayerID, difficulty: difficulty)

        case .drewCard:
            makeAIDrawnCardDecision(playerID: currentPlayerID, difficulty: difficulty)
        }

        if ruleOptions.unoCallPenalty && playerWhoNeedsToCallHana == currentPlayerID {
            try? callHana(playerID: currentPlayerID)
        }
    }

    // MARK: - Play or Draw

    private mutating func makeAIPlayOrDraw(
        playerID: PlayerID,
        difficulty: AIDifficulty
    ) {
        if pendingDrawCount > 0 {
            if ruleOptions.stackingDrawCards {
                let stackable: [Card] = playableCards(for: playerID)
                if let card: Card = stackable.first {
                    let color: CardColor? = card.kind.isWild
                        ? chooseBestColor(for: playerID, difficulty: difficulty)
                        : nil
                    try? playCard(card.id, chosenColor: color)
                    return
                }
            }
            try? drawCard()
            return
        }

        let playable: [Card] = playableCards(for: playerID)
        if playable.isEmpty {
            try? drawCard()
            return
        }

        let card: Card = chooseCard(from: playable, difficulty: difficulty)
        let color: CardColor? = card.kind.isWild
            ? chooseBestColor(for: playerID, difficulty: difficulty)
            : nil
        let swapTarget: PlayerID? = needsSwapTarget(card)
            ? chooseSwapTarget(for: playerID, difficulty: difficulty)
            : nil

        try? playCard(card.id, chosenColor: color, swapWithPlayerID: swapTarget)
    }

    // MARK: - Drew Card Decision

    private mutating func makeAIDrawnCardDecision(
        playerID: PlayerID,
        difficulty: AIDifficulty
    ) {
        guard let playerIndex: Int = playerHandIndex(for: playerID) else { return }
        guard let lastCardID: CardID = playerHands[playerIndex].cards.last,
              let lastCard: Card = cardsMap[lastCardID],
              let topCard: Card = topDiscardCard,
              lastCard.kind.canPlayOn(topKind: topCard.kind, activeColor: activeColor)
        else {
            try? passAfterDraw()
            return
        }

        let color: CardColor? = lastCard.kind.isWild
            ? chooseBestColor(for: playerID, difficulty: difficulty)
            : nil
        let swapTarget: PlayerID? = needsSwapTarget(lastCard)
            ? chooseSwapTarget(for: playerID, difficulty: difficulty)
            : nil

        try? playCard(lastCardID, chosenColor: color, swapWithPlayerID: swapTarget)
    }

    // MARK: - Card Selection

    private func chooseCard(
        from cards: [Card],
        difficulty: AIDifficulty
    ) -> Card {
        switch difficulty {
        case .easy:
            return cards.randomElement()!

        case .medium:
            let nonWilds: [Card] = cards.filter { $0.kind.isWild == false }
            if let card: Card = nonWilds.randomElement() {
                return card
            }
            return cards.randomElement()!

        case .hard:
            let scored: [(card: Card, score: Int)] = cards.map { card in
                (card: card, score: scoreCardForPlay(card))
            }
            let best: [(card: Card, score: Int)] = scored.sorted { $0.score > $1.score }
            return best.first!.card
        }
    }

    private func scoreCardForPlay(_ card: Card) -> Int {
        switch card.kind {
        case .number(_, let rank):
            rank.rawValue
        case .skip, .reverse:
            25
        case .drawTwo:
            30
        case .wild:
            -10
        case .wildDrawFour:
            -5
        }
    }

    // MARK: - Color Selection

    private func chooseBestColor(
        for playerID: PlayerID,
        difficulty: AIDifficulty
    ) -> CardColor {
        guard difficulty != .easy else {
            return CardColor.allCases.randomElement()!
        }

        guard let playerIndex: Int = playerHandIndex(for: playerID) else {
            return CardColor.allCases.randomElement()!
        }

        var colorCounts: [CardColor: Int] = [:]
        for cardID in playerHands[playerIndex].cards {
            if let card: Card = cardsMap[cardID],
               let color: CardColor = card.kind.color,
               card.kind.isWild == false {
                colorCounts[color, default: 0] += 1
            }
        }

        return colorCounts.max(by: { $0.value < $1.value })?.key
            ?? CardColor.allCases.randomElement()!
    }

    // MARK: - Seven/Zero Helpers

    private func needsSwapTarget(_ card: Card) -> Bool {
        guard ruleOptions.sevenZero else { return false }
        if case .number(_, .seven) = card.kind { return true }
        return false
    }

    private func chooseSwapTarget(
        for playerID: PlayerID,
        difficulty: AIDifficulty
    ) -> PlayerID? {
        playerHands
            .filter { $0.player.id != playerID }
            .min(by: { $0.cards.count < $1.cards.count })?
            .player.id
    }
}
