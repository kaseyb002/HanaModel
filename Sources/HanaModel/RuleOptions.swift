import Foundation

/// Configurable house rules for a Hana round.
///
/// ``classic`` matches official Mattel Uno. Individual flags can be toggled for
/// common house-rule variants.
public struct RuleOptions: Equatable, Codable, Sendable {
    /// When `true`, a player facing a Draw Two / Wild Draw Four penalty may play
    /// another card of the same draw type to stack the penalty onto the next player
    /// instead of drawing. Draw Twos stack with Draw Twos; Wild Draw Fours stack
    /// with Wild Draw Fours. When `false`, the affected player must draw the
    /// pending cards and cannot respond by playing.
    ///
    /// Official Mattel: off.
    public var stackingDrawCards: Bool

    /// When `true`, a player who is not currently up may interrupt and play out of
    /// turn if they hold an exact match for the top discard (same kind — e.g. both
    /// Red 7s). Play then continues from that jumper. When `false`, only the
    /// current player may play.
    ///
    /// Official Mattel: off.
    public var jumpIn: Bool

    /// When `true`, special number-card effects are enabled:
    /// - Playing a **7** swaps that player's hand with another player's (must
    ///   choose a swap target).
    /// - Playing a **0** rotates every player's hand one seat in the current
    ///   direction of play.
    /// When `false`, 7s and 0s are ordinary number cards.
    ///
    /// Official Mattel: off.
    public var sevenZero: Bool

    /// When `true`, after drawing a playable card the player must play it — they
    /// cannot pass. When `false`, they may either play the drawn card or pass and
    /// keep it.
    ///
    /// Official Mattel: off (playing the drawn card is optional).
    public var forcePlayDrawnCard: Bool

    /// When `true`, a Wild Draw Four may be played even if the player still holds
    /// a card matching the active color. When `false`, Wild Draw Four is only
    /// legal if the player has no card of the active color.
    ///
    /// Official Mattel: off.
    public var allowWildDrawFourAnytime: Bool

    /// When `true`, a player who drops to one card must call "하나" (Hana / Uno).
    /// If they forget, another player can catch them and force a 2-card penalty.
    /// When `false`, no call is required and catch/call actions are unavailable.
    ///
    /// Official Mattel: on.
    public var unoCallPenalty: Bool

    public init(
        stackingDrawCards: Bool = false,
        jumpIn: Bool = false,
        sevenZero: Bool = false,
        forcePlayDrawnCard: Bool = false,
        allowWildDrawFourAnytime: Bool = false,
        unoCallPenalty: Bool = false
    ) {
        self.stackingDrawCards = stackingDrawCards
        self.jumpIn = jumpIn
        self.sevenZero = sevenZero
        self.forcePlayDrawnCard = forcePlayDrawnCard
        self.allowWildDrawFourAnytime = allowWildDrawFourAnytime
        self.unoCallPenalty = unoCallPenalty
    }

    /// Official Mattel Uno rules.
    public static let classic: RuleOptions = .init(unoCallPenalty: true)
}
