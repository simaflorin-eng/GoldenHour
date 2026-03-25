import SwiftUI

@main
struct GoldenHourApp: App {
    @AppStorage("appTheme") private var appTheme: Int = 0
    @StateObject private var healthManager = HealthKitManager()
    
    // Adăugăm scenePhase pentru a detecta când deschizi aplicația sau revii în ea
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView(healthManager: healthManager)
                .preferredColorScheme(selectedColorScheme)
                .task {
                    // Se execută la prima deschidere a aplicației
                    await healthManager.requestAuthorization()
                }
                // Refresh automat: detectăm când aplicația trece din fundal în prim-plan
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        healthManager.refresh()
                    }
                }
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
