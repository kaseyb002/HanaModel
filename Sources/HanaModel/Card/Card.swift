import Foundation

public typealias CardID = Int

public struct Card: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public var kind: Kind

    public enum Kind: Equatable, Codable, Sendable {
        case number(color: CardColor, rank: CardRank)
        case skip(color: CardColor)
        case reverse(color: CardColor)
        case drawTwo(color: CardColor)
        case wild(chosenColor: CardColor?)
        case wildDrawFour(chosenColor: CardColor?)
    }

    public init(id: CardID, kind: Kind) {
        self.id = id
        self.kind = kind
    }
}
