import Foundation

extension Round {
    mutating func calculatePoints(winnerIndex: Int) {
        var totalPoints: Int = 0
        for (index, playerHand) in playerHands.enumerated() {
            if index != winnerIndex {
                let handPoints: Int = playerHand.cards.totalPoints(cardsMap: cardsMap)
                totalPoints += handPoints
            }
        }
        playerHands[winnerIndex].player.points += totalPoints
    }
}
