import SwiftUI
import WidgetKit

@main
struct GoldenHourApp: App {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var locationManager = LocationManager()
    @State private var didRequestInitialPermissions = false
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView(healthManager: healthManager, locationManager: locationManager)
                .preferredColorScheme(selectedColorScheme)
                .task {
                    syncSharedLanguageState()
                    await requestInitialPermissionsIfNeeded()
                }
                .onChange(of: appLanguage) { _, _ in
                    syncSharedLanguageState()
                    healthManager.updateLiveActivity()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        handleActiveScene()
                    }
                }
        }
    }

    private func handleActiveScene() {
        syncSharedLanguageState()
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

    private func syncSharedLanguageState() {
        sharedDefaults?.set(appLanguage, forKey: "appLanguage")
        WidgetCenter.shared.reloadAllTimelines()
    }

    var selectedColorScheme: ColorScheme? {
        switch appTheme {
        case 1, 2: return .dark
        default: return nil
        }
    }
}
