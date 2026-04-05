import SwiftUI

@main
struct GoldenHourApp: App {
    @AppStorage("appTheme") private var appTheme: Int = 0
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var locationManager = LocationManager()
    @State private var didRequestInitialPermissions = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView(healthManager: healthManager, locationManager: locationManager)
                .preferredColorScheme(selectedColorScheme)
                .task {
                    await requestInitialPermissionsIfNeeded()
                }
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
            locationManager.requestLocation()
        }
    }

    private func requestInitialPermissionsIfNeeded() async {
        guard !didRequestInitialPermissions else { return }
        didRequestInitialPermissions = true

        await healthManager.requestAuthorization()
        NotificationManager.instance.requestAuthorization()
        locationManager.requestLocation()
    }
    
    var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}
