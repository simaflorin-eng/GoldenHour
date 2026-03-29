import Foundation

// Acest fișier trebuie să fie SINGURUL loc unde este definit DayPhase
enum DayPhase: String, CaseIterable {
    case morningPrep = "morning_prep"
    case focus = "focus"
    case caffeine = "caffeine"
    case afternoon = "afternoon"
    case sunset = "sunset"
    case idle = "idle"

    var icon: String {
        switch self {
        case .morningPrep: return "sunrise.fill"
        case .focus: return "brain.head.profile"
        case .caffeine: return "cup.and.saucer.fill"
        case .afternoon: return "sun.max.trianglebadge.exclamationmark"
        case .sunset: return "sunset.fill"
        case .idle: return "moon.stars.fill"
        }
    }

    var hexColor: String {
        switch self {
        case .morningPrep: return "#00FFFF"
        case .focus: return "#FF9500"
        case .caffeine: return "#A2845E"
        case .afternoon: return "#2FBF71"
        case .sunset: return "#5856D6"
        case .idle: return "#AF52DE"
        }
    }

    var appearsInPrimaryCharts: Bool {
        self != .idle
    }

    var visualFallback: DayPhase {
        self == .idle ? .sunset : self
    }

    var usesCompletedDayBackground: Bool {
        self == .idle
    }
}
