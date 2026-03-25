import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, watchOS 11.0, macOS 15.0, visionOS 2.0, *)
struct Golden_Hour_WidgetControl: ControlWidget {
    static let kind: String = "com.florinsima.GoldenHour.TimerControl"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: GoldenControlProvider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(nameForTimer: value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("Control widget for Golden Hour.")
    }
}

@available(iOS 18.0, watchOS 11.0, macOS 15.0, visionOS 2.0, *)
struct GoldenControlProvider: AppIntentControlValueProvider {
    func previewValue(configuration: TimerConfiguration) -> GoldenControlValue {
        GoldenControlValue(isRunning: false, name: configuration.timerName)
    }

    func currentValue(configuration: TimerConfiguration) async throws -> GoldenControlValue {
        return GoldenControlValue(isRunning: true, name: configuration.timerName)
    }
}

struct GoldenControlValue {
    var isRunning: Bool
    var name: String
}

@available(iOS 18.0, watchOS 11.0, macOS 15.0, visionOS 2.0, *)
struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Configuration"
    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
    
    init() {}
}

@available(iOS 18.0, watchOS 11.0, macOS 15.0, visionOS 2.0, *)
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start Timer"
    
    @Parameter(title: "Name") 
    var timerName: String
    
    @Parameter(title: "Is Running") 
    var value: Bool
    
    init() {}
    
    init(nameForTimer: String) {
        self.timerName = nameForTimer
    }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
