import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled: Bool = true
    @AppStorage("dashboardChartStyle") private var dashboardChartStyle: String = DashboardChartStyle.neon.rawValue
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme
    
    private let meshPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(1.0, 1.0)
    ]

    private var meshColors: [Color] {
        if healthManager.currentPhase.usesCompletedDayBackground {
            return [
                Color(red: 0.2, green: 0.2, blue: 0.22),
                Color(red: 0.14, green: 0.14, blue: 0.16),
                Color(red: 0.1, green: 0.1, blue: 0.12),
                .black
            ]
        }

        let intensity = colorScheme == .dark ? 0.9 : 0.6
        let phase = healthManager.currentPhase.visualFallback
        let base: Color
        
        switch phase {
        case .morningPrep: base = .cyan
        case .focus: base = .orange
        case .caffeine: base = Color(hexRGB: phase.hexColor, fallback: .brown)
        case .afternoon: base = Color(hexRGB: phase.hexColor, fallback: .green)
        case .sunset: base = .indigo
        case .idle: base = .purple
        }
        
        return [base.opacity(intensity), base.opacity(intensity * 0.5), base.opacity(0.3), .black]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                MeshGradient(width: 2, height: 2, points: meshPoints, colors: meshColors)
                    .ignoresSafeArea()
                    .blur(radius: 50)
                    .animation(.spring(response: 1.5, dampingFraction: 0.9), value: healthManager.currentPhase)
                
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()
                    .opacity(colorScheme == .dark ? 0.45 : 0.25)

                List {
                    Section(header: Text(AppTranslation.get("language", lang: appLanguage))) {
                        Picker(AppTranslation.get("language", lang: appLanguage), selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.name).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(header: Text(AppTranslation.get("theme", lang: appLanguage))) {
                        Picker(AppTranslation.get("theme", lang: appLanguage), selection: $appTheme) {
                            Text(AppTranslation.get("theme_system", lang: appLanguage)).tag(0)
                            Text(AppTranslation.get("theme_light", lang: appLanguage)).tag(1)
                            Text(AppTranslation.get("theme_dark", lang: appLanguage)).tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.primary.opacity(0.05))

                    Section(header: Text(AppTranslation.get("chart_style", lang: appLanguage))) {
                        Picker(AppTranslation.get("chart_style", lang: appLanguage), selection: $dashboardChartStyle) {
                            ForEach(DashboardChartStyle.allCases) { style in
                                Text(AppTranslation.get(style.titleKey, lang: appLanguage)).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(
                        header: Text(AppTranslation.get("live_activities_title", lang: appLanguage)),
                        footer: Text(AppTranslation.get("live_activities_desc", lang: appLanguage))
                    ) {
                        Toggle(AppTranslation.get("live_activities_title", lang: appLanguage), isOn: $liveActivitiesEnabled)
                            .tint(.orange)
                            .onChange(of: liveActivitiesEnabled) { _, newValue in
                                if newValue {
                                    healthManager.updateLiveActivity()
                                } else {
                                    healthManager.stopAllActivities()
                                }
                            }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(header: Text(AppTranslation.get("about", lang: appLanguage))) {
                        NavigationLink(destination: AboutView(healthManager: healthManager)) {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundColor(.blue)
                                Text(AppTranslation.get("about", lang: appLanguage))
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(AppTranslation.get("settings", lang: appLanguage))
            }
        }
    }
}
