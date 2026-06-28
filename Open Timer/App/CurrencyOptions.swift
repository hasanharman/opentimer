import Foundation

enum CurrencyOption: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case tryLira = "TRY"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .tryLira: return "TRY"
        }
    }
}
