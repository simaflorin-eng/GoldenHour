import SwiftUI

@main
struct GoldenHourApp: App {
    @AppStorage("appTheme") private var appTheme: Int = 0
    @StateObject private var healthManager = HealthKitManager()
    @State private var didRequestInitialPermissions = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView(healthManager: healthManager)
                .preferredColorScheme(selectedColorScheme)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        handleActiveScene()
                    }
                }
        }
    }

    private func handleActiveScene() {
        if didRequestInitialPermissions {
            healthManager.refresh()
            return
        }

        didRequestInitialPermissions = true
        NotificationManager.instance.requestAuthorization()

        Task(priority: .userInitiated) {
            await healthManager.requestAuthorization()
        }
    }
    
    var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}
