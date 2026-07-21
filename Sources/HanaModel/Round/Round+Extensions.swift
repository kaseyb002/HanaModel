import Foundation

extension Round {
    public var currentPlayerID: PlayerID? {
        switch state {
        case .waitingForPlayer(let playerID, _): playerID
        case .roundComplete: nil
        }
    }

    public var currentPlayerHandIndex: Int? {
        guard let currentPlayerID else { return nil }
        return playerHandIndex(for: currentPlayerID)
    }

    public var currentPlayerHand: PlayerHand? {
        guard let index: Int = currentPlayerHandIndex else { return nil }
        return playerHands[index]
    }

    public var topDiscardCard: Card? {
        guard let topCardID: CardID = discardPile.last else { return nil }
        return cardsMap[topCardID]
    }

    public func playerHandIndex(for playerID: PlayerID) -> Int? {
        playerHands.firstIndex { $0.player.id == playerID }
    }

    public func nextPlayerIndex(from index: Int) -> Int {
        switch direction {
        case .clockwise:
            (index + 1) % playerHands.count
        case .counterclockwise:
            (index - 1 + playerHands.count) % playerHands.count
        }
    }

    public func playableCards(for playerID: PlayerID) -> [Card] {
        guard let index: Int = playerHandIndex(for: playerID),
              let topCard: Card = topDiscardCard
        else { return [] }

        // After drawing, only the drawn card (last in hand) may be played.
        if case .waitingForPlayer(let currentID, .drewCard) = state,
           currentID == playerID {
            guard let lastCardID: CardID = playerHands[index].cards.last,
                  let card: Card = cardsMap[lastCardID]
            else { return [] }
            return isPlayable(
                card,
                topCard: topCard,
                playerIndex: index
            ) ? [card] : []
        }

        return playerHands[index].cards.compactMap { cardID in
            guard let card: Card = cardsMap[cardID] else { return nil }
            return isPlayable(
                card,
                topCard: topCard,
                playerIndex: index
            ) ? card : nil
        }
    }

    private func isPlayable(
        _ card: Card,
        topCard: Card,
        playerIndex: Int
    ) -> Bool {
        if pendingDrawCount > 0 && ruleOptions.stackingDrawCards {
            switch (topCard.kind, card.kind) {
            case (.drawTwo, .drawTwo): return true
            case (.wildDrawFour, .wildDrawFour): return true
            default: return false
            }
        }

        guard card.kind.canPlayOn(topKind: topCard.kind, activeColor: activeColor) else {
            return false
        }

        if case .wildDrawFour = card.kind,
           ruleOptions.allowWildDrawFourAnytime == false {
            let hasMatchingColor: Bool = playerHands[playerIndex].cards.contains { id in
                guard let other: Card = cardsMap[id] else { return false }
                return other.kind.color == activeColor && other.id != card.id
            }
            if hasMatchingColor { return false }
        }

        return true
    }

    public var logValue: String {
        """
        State: \(state.logValue)
        Direction: \(direction.rawValue)
        Active color: \(activeColor.logValue)
        Deck remaining: \(deck.count)
        Discard pile count: \(discardPile.count)
        Top discard: \(topDiscardCard?.kind.logValue ?? "None")
        Pending draw: \(pendingDrawCount)
        Current player: \(currentPlayerHand?.player.name ?? "None")

        \(playerHandsLogValue)
        """
    }

    private var playerHandsLogValue: String {
        playerHands.map { hand in
            let cards: String = hand.cards
                .compactMap { cardsMap[$0]?.kind.logValue }
                .joined(separator: ", ")
            return "\(hand.player.name) (\(hand.cards.count) cards): [\(cards)]"
        }.joined(separator: "\n")
    }
}
