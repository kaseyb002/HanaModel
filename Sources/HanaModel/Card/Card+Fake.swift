import Foundation

extension Card {
    public static func fake(
        id: CardID = Int.random(in: 0...999),
        kind: Kind = .number(color: .red, rank: .five)
    ) -> Card {
        .init(id: id, kind: kind)
    }
}
