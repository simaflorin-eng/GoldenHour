import SwiftUI

struct AboutView: View {
    @ObservedObject var healthManager: HealthKitManager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appLanguage") private var appLanguage: String = "ro"
    @State private var showingHubermanDetails = false
    
    var body: some View {
        ZStack {
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Card 1: Introducere
                    VStack(spacing: 12) {
                        Text(AppTranslation.get("about_q", lang: appLanguage))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        
                        Text(AppTranslation.get("about_intro", lang: appLanguage))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(25)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    .padding(.top, 10)
                    
                    // Card 2: Etapele Zilei
                    VStack(alignment: .leading, spacing: 20) {
                        Text(AppTranslation.get("stages_header", lang: appLanguage))
                            .font(.system(size: 14, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        
                        aboutSection(title: "morning_prep_t", info: "morning_prep_d", icon: "sunrise.fill", color: .cyan)
                        aboutSection(title: "peak_focus_t", info: "peak_focus_d", icon: "brain.head.profile", color: .orange)
                        aboutSection(title: "caffeine_cutoff_t", info: "caffeine_cutoff_d", icon: "cup.and.saucer.fill", color: .brown)
                        aboutSection(title: "sunset_walk_t", info: "sunset_walk_d", icon: "sunset.fill", color: .indigo)
                        aboutSection(title: "idle_phase_t", info: "idle_phase_d", icon: "moon.stars.fill", color: .purple)
                    }
                    .padding(25)
                    .background(.ultraThinMaterial)
                    .cornerRadius(30)
                    
                    // Card 3: Baza Științifică & Filozofia
                    VStack(alignment: .leading, spacing: 15) {
                        Button {
                            showingHubermanDetails = true
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text(AppTranslation.get("science_header", lang: appLanguage))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(AppTranslation.get("science_content", lang: appLanguage))
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Divider().background(Color.primary.opacity(0.1)).padding(.vertical, 5)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundColor(.orange)
                                Text(AppTranslation.get("philosophy_title", lang: appLanguage))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            
                            Text(AppTranslation.get("philosophy_text", lang: appLanguage))
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(25)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .cornerRadius(30)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(AppTranslation.get("about_title", lang: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHubermanDetails) {
            hubermanDetailsView
        }
    }
    
    // Popup Huberman
    private var hubermanDetailsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text(AppTranslation.get("science_content", lang: appLanguage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                    
                    hubermanPoint(title: "huberman_morning_light_t", description: "huberman_morning_light_d", icon: "sun.max.fill", color: .yellow)
                    hubermanPoint(title: "huberman_delay_caffeine_t", description: "huberman_delay_caffeine_d", icon: "timer", color: .orange)
                    hubermanPoint(title: "huberman_focus_window_t", description: "huberman_focus_window_d", icon: "brain.head.profile", color: .blue)
                    hubermanPoint(title: "huberman_sunset_view_t", description: "huberman_sunset_view_d", icon: "sunset.fill", color: .indigo)
                    hubermanPoint(title: "huberman_caffeine_cutoff_t", description: "huberman_caffeine_cutoff_d", icon: "cup.and.saucer.fill", color: .brown)
                }
                .padding(24)
            }
            .navigationTitle(AppTranslation.get("huberman_title", lang: appLanguage))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(AppTranslation.get("close", lang: appLanguage)) {
                        showingHubermanDetails = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func hubermanPoint(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(AppTranslation.get(title, lang: appLanguage))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(AppTranslation.get(description, lang: appLanguage))
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var backgroundView: some View {
        let intensity = colorScheme == .dark ? 0.9 : 0.6
        let phase = healthManager.currentPhase
        let base: Color = {
            switch phase {
            case .morningPrep: return .cyan
            case .focus: return .orange
            case .caffeine: return .brown
            case .sunset: return .indigo
            case .idle: return .purple
            }
        }()
        
        return ZStack {
            MeshGradient(
                width: 2, height: 2,
                points: [[0, 0], [1, 0], [0, 1], [1, 1]],
                colors: [base.opacity(intensity), base.opacity(intensity * 0.4), base.opacity(0.2), .black]
            )
            .ignoresSafeArea()
            .blur(radius: 60)
            
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
                .opacity(colorScheme == .dark ? 0.45 : 0.15)
        }
    }
    
    private func aboutSection(title: String, info: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 22))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(AppTranslation.get(title, lang: appLanguage))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                
                Text(AppTranslation.get(info, lang: appLanguage))
                    .font(.system(size: 14, design: .rounded))
                    .lineSpacing(4)
                    .foregroundColor(.secondary)
            }
        }
    }
}
