import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case romanian = "ro"
    case english = "en"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case german = "de"
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .romanian: return "Română"
        case .english: return "English"
        case .french: return "Français"
        case .spanish: return "Español"
        case .italian: return "Italiano"
        case .german: return "Deutsch"
        }
    }
}
