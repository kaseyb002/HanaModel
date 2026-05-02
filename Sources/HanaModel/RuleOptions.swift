import Foundation

public struct RuleOptions: Equatable, Codable, Sendable {
    public var stackingDrawCards: Bool
    public var jumpIn: Bool
    public var sevenZero: Bool
    public var drawUntilPlayable: Bool
    public var forcePlayDrawnCard: Bool
    public var allowWildDrawFourAnytime: Bool
    public var unoCallPenalty: Bool

    public init(
        stackingDrawCards: Bool = false,
        jumpIn: Bool = false,
        sevenZero: Bool = false,
        drawUntilPlayable: Bool = false,
        forcePlayDrawnCard: Bool = false,
        allowWildDrawFourAnytime: Bool = false,
        unoCallPenalty: Bool = false
    ) {
        self.stackingDrawCards = stackingDrawCards
        self.jumpIn = jumpIn
        self.sevenZero = sevenZero
        self.drawUntilPlayable = drawUntilPlayable
        self.forcePlayDrawnCard = forcePlayDrawnCard
        self.allowWildDrawFourAnytime = allowWildDrawFourAnytime
        self.unoCallPenalty = unoCallPenalty
    }

    public static let classic: RuleOptions = .init()
}
