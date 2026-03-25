import SwiftUI

struct MainTabView: View {
    @ObservedObject var healthManager: HealthKitManager
    @StateObject private var locationManager = LocationManager()
    @AppStorage("appLanguage") private var appLanguage: String = "ro"
    
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
            healthManager.locationManager = locationManager
            locationManager.requestLocation()
            
            Task {
                await healthManager.requestAuthorization()
                NotificationManager.instance.requestAuthorization()
            }
        }
    }
}

