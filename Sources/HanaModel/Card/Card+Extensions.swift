import Foundation

extension Card.Kind {
    public var color: CardColor? {
        switch self {
        case .number(let color, _): color
        case .skip(let color): color
        case .reverse(let color): color
        case .drawTwo(let color): color
        case .wild(let chosenColor): chosenColor
        case .wildDrawFour(let chosenColor): chosenColor
        }
    }

    public var rank: CardRank? {
        switch self {
        case .number(_, let rank): rank
        default: nil
        }
    }

    public var isWild: Bool {
        switch self {
        case .wild, .wildDrawFour: true
        default: false
        }
    }

    public var isActionCard: Bool {
        switch self {
        case .skip, .reverse, .drawTwo: true
        default: false
        }
    }

    public var points: Int {
        switch self {
        case .number(_, let rank): rank.rawValue
        case .skip, .reverse, .drawTwo: 20
        case .wild, .wildDrawFour: 50
        }
    }

    public func canPlayOn(topKind: Card.Kind, activeColor: CardColor) -> Bool {
        switch self {
        case .wild:
            return true

        case .wildDrawFour:
            return true

        case .number(let color, let rank):
            if color == activeColor { return true }
            if case .number(_, let topRank) = topKind, topRank == rank { return true }
            return false

        case .skip(let color):
            if color == activeColor { return true }
            if case .skip = topKind { return true }
            return false

        case .reverse(let color):
            if color == activeColor { return true }
            if case .reverse = topKind { return true }
            return false

        case .drawTwo(let color):
            if color == activeColor { return true }
            if case .drawTwo = topKind { return true }
            return false
        }
    }

    public var logValue: String {
        switch self {
        case .number(let color, let rank):
            "\(rank.rawValue)\(color.logValue)"
        case .skip(let color):
            "S\(color.logValue)"
        case .reverse(let color):
            "R\(color.logValue)"
        case .drawTwo(let color):
            "+2\(color.logValue)"
        case .wild(let chosenColor):
            "W\(chosenColor?.logValue ?? "🌈")"
        case .wildDrawFour(let chosenColor):
            "+4\(chosenColor?.logValue ?? "🌈")"
        }
    }
}

extension Card {
    public var logValue: String {
        "ID:\(id) \(kind.logValue)"
    }
}

// MARK: - Deck Generation

extension [Card] {
    public static func deck() -> [Card] {
        let placeholder: Int = 0
        var cards: [Card] = []

        for color in CardColor.allCases {
            cards.append(Card(id: placeholder, kind: .number(color: color, rank: .zero)))

            for rank in CardRank.allCases where rank != .zero {
                cards.append(Card(id: placeholder, kind: .number(color: color, rank: rank)))
                cards.append(Card(id: placeholder, kind: .number(color: color, rank: rank)))
            }

            cards.append(Card(id: placeholder, kind: .skip(color: color)))
            cards.append(Card(id: placeholder, kind: .skip(color: color)))
            cards.append(Card(id: placeholder, kind: .reverse(color: color)))
            cards.append(Card(id: placeholder, kind: .reverse(color: color)))
            cards.append(Card(id: placeholder, kind: .drawTwo(color: color)))
            cards.append(Card(id: placeholder, kind: .drawTwo(color: color)))
        }

        for _ in 0..<4 {
            cards.append(Card(id: placeholder, kind: .wild(chosenColor: nil)))
            cards.append(Card(id: placeholder, kind: .wildDrawFour(chosenColor: nil)))
        }

        let shuffledIDs: [Int] = (0..<cards.count).shuffled()
        return zip(cards, shuffledIDs).map { card, cardID in
            Card(id: cardID, kind: card.kind)
        }
    }

    public var totalPoints: Int {
        reduce(0) { $0 + $1.kind.points }
    }

    public var logValue: String {
        map { $0.kind.logValue }.joined(separator: ", ")
    }
}

extension [CardID] {
    public func totalPoints(cardsMap: [CardID: Card]) -> Int {
        reduce(0) { $0 + (cardsMap[$1]?.kind.points ?? 0) }
    }
}

extension [CardID: Card] {
    public func findCards(byIDs cardIDs: [CardID]) -> [Card] {
        cardIDs.compactMap { self[$0] }
    }
}
