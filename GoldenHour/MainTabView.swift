import SwiftUI

struct MainTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @State private var didConfigureManagers = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    
    var body: some View {
        TabView {
            ContentView(healthManager: healthManager, locationManager: locationManager)
                .tabItem {
                    Label(AppTranslation.get("dashboard", lang: appLanguage), systemImage: "clock.fill")
                }
            
            SettingsView(healthManager: healthManager)
                .tabItem {
                    Label(AppTranslation.get("settings", lang: appLanguage), systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            guard !didConfigureManagers else { return }
            didConfigureManagers = true

            healthManager.connectLocationManager(locationManager)
        }
    }
}
