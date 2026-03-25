import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "ro"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled: Bool = true
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme
    
    private let meshPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(1.0, 1.0)
    ]

    private var meshColors: [Color] {
        let intensity = colorScheme == .dark ? 0.9 : 0.6
        let phase = healthManager.currentPhase
        let base: Color
        
        switch phase {
        case .morningPrep: base = .cyan
        case .focus: base = .orange
        case .caffeine: base = Color(hexRGB: phase.hexColor, fallback: .brown)
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
                    Section(header: Text(GoldenHourTranslation.get("language", lang: appLanguage))) {
                        Picker(GoldenHourTranslation.get("language", lang: appLanguage), selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.name).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(header: Text(GoldenHourTranslation.get("theme", lang: appLanguage))) {
                        Picker(GoldenHourTranslation.get("theme", lang: appLanguage), selection: $appTheme) {
                            Text(GoldenHourTranslation.get("theme_system", lang: appLanguage)).tag(0)
                            Text(GoldenHourTranslation.get("theme_light", lang: appLanguage)).tag(1)
                            Text(GoldenHourTranslation.get("theme_dark", lang: appLanguage)).tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(
                        header: Text(GoldenHourTranslation.get("live_activities_title", lang: appLanguage)),
                        footer: Text(GoldenHourTranslation.get("live_activities_desc", lang: appLanguage))
                    ) {
                        Toggle(GoldenHourTranslation.get("live_activities_title", lang: appLanguage), isOn: $liveActivitiesEnabled)
                            .tint(.orange)
                            .onChange(of: liveActivitiesEnabled) { newValue in
                                if newValue {
                                    healthManager.updateLiveActivity()
                                } else {
                                    healthManager.stopAllActivities()
                                }
                            }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section(header: Text(GoldenHourTranslation.get("about", lang: appLanguage))) {
                        NavigationLink(destination: AboutView(healthManager: healthManager)) {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundColor(.blue)
                                Text(GoldenHourTranslation.get("about", lang: appLanguage))
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(GoldenHourTranslation.get("settings", lang: appLanguage))
            }
        }
    }
}

