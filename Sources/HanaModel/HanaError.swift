import Foundation

public enum HanaError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notYourTurn
    case cardNotInHand
    case cardNotPlayable
    case canOnlyPlayDrawnCard
    case notInDrawPhase
    case cannotPassMustPlay
    case invalidColorChoice
    case wildDrawFourNotAllowed
    case mustRespondToDrawPenalty
    case jumpInNotEnabled
    case invalidJumpIn
    case sevenZeroNotEnabled
    case mustSpecifySwapTarget
    case cannotSwapWithSelf
    case playerNotFound
    case hanaCallNotNeeded
    case cannotCatchOwnHana
    case noMissedHanaToCatch
    case roundAlreadyComplete
}
