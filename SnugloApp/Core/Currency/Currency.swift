import SwiftUI

enum Currency: String, CaseIterable, Identifiable, Codable {
    case coin
    case gem
    case ticket
    case cup

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .coin:   return "currency.coin"
        case .gem:    return "currency.gem"
        case .ticket: return "currency.ticket"
        case .cup:    return "currency.cup"
        }
    }

    var sfSymbol: String {
        switch self {
        case .coin:   return "circle.hexagongrid.fill"
        case .gem:    return "diamond.fill"
        case .ticket: return "ticket.fill"
        case .cup:    return "trophy.fill"
        }
    }

    // cup is prestige / display-only — never spendable
    var isSpendable: Bool { self != .cup }

    // Maps to existing AppColors tokens only — no new colors introduced
    var tint: Color {
        switch self {
        case .coin:   return AppColors.tertiary
        case .gem:    return AppColors.primary
        case .ticket: return AppColors.secondary
        case .cup:    return AppColors.tertiary
        }
    }
}

struct CurrencyRate {
    // Coin cost for 1 gem
    static let coinPerGem: Int = 100
    // Gem cost for 1 ticket
    static let gemPerTicket: Int = 50
}
