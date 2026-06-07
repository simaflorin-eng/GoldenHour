import SwiftUI
import StoreKit
import UIKit

@MainActor
struct RootView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.requestReview) private var requestReview
    @State private var selectedTab: GoldenHourTab = .dashboard
    @State private var didConfigureManagers = false
    @State private var showReviewPrompt = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("reviewPromptLaunchCount") private var reviewPromptLaunchCount = 0
    @AppStorage("reviewPromptLastShownAt") private var reviewPromptLastShownAt = 0.0
    @AppStorage("reviewPromptCompleted") private var reviewPromptCompleted = false

    private let reviewPromptStartCount = 8
    private let reviewPromptRepeatInterval = 12
    private let reviewPromptCooldown: TimeInterval = 60 * 60 * 24 * 45
    private let appStoreReviewURL = URL(string: "itms-apps://itunes.apple.com/app/id6762508692?action=write-review")

    init(healthManager: HealthKitManager, locationManager: LocationManager) {
        self.healthManager = healthManager
        self.locationManager = locationManager
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            activeContent

            GHTabBar(selectedTab: $selectedTab, accentColor: healthManager.currentPhase.visualFallback.accentColor)
                .padding(.horizontal, GHSpacing.xl)
                .padding(.bottom, GHSpacing.lg)
        }
        .onAppear {
            guard !didConfigureManagers else { return }
            didConfigureManagers = true
            healthManager.connectLocationManager(locationManager)
            registerLaunchAndScheduleReviewPrompt()
        }
        .alert(
            AppTranslation.get("review_prompt_title", lang: appLanguage),
            isPresented: $showReviewPrompt
        ) {
            Button(AppTranslation.get("review_prompt_cta", lang: appLanguage)) {
                reviewPromptCompleted = true
                openReviewPage()
            }

            Button(AppTranslation.get("review_prompt_later", lang: appLanguage), role: .cancel) {}
        } message: {
            Text(AppTranslation.get("review_prompt_message", lang: appLanguage))
        }
    }

    @ViewBuilder
    private var activeContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(healthManager: healthManager, locationManager: locationManager)
        case .settings:
            RedesignedSettingsView(healthManager: healthManager)
        }
    }

    private func registerLaunchAndScheduleReviewPrompt() {
        guard !reviewPromptCompleted else { return }
        reviewPromptLaunchCount += 1
        guard shouldPresentReviewPrompt(now: Date()) else { return }
        reviewPromptLastShownAt = Date().timeIntervalSince1970
        showReviewPrompt = true
    }

    private func shouldPresentReviewPrompt(now: Date) -> Bool {
        guard reviewPromptLaunchCount >= reviewPromptStartCount else { return false }
        let launchesSinceStart = reviewPromptLaunchCount - reviewPromptStartCount
        guard launchesSinceStart % reviewPromptRepeatInterval == 0 else { return false }
        guard reviewPromptLastShownAt > 0 else { return true }
        let elapsed = now.timeIntervalSince1970 - reviewPromptLastShownAt
        return elapsed >= reviewPromptCooldown
    }

    private func openReviewPage() {
        guard let appStoreReviewURL, UIApplication.shared.canOpenURL(appStoreReviewURL) else {
            requestReview()
            return
        }

        UIApplication.shared.open(appStoreReviewURL)
    }
}

private enum GoldenHourTab: String, CaseIterable, Identifiable {
    case dashboard
    case settings

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }

    func title(lang: String) -> String {
        switch self {
        case .dashboard: return AppTranslation.get("dashboard", lang: lang)
        case .settings: return AppTranslation.get("settings", lang: lang)
        }
    }
}

private struct GHTabBar: View {
    @Binding var selectedTab: GoldenHourTab
    let accentColor: Color
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: GHSpacing.sm) {
            HStack(spacing: GHSpacing.sm) {
                ForEach(GoldenHourTab.allCases) { tab in
                    tabButton(tab)
                }
            }
        }
        .padding(GHSpacing.xs)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .glassEffect(.regular.tint(accentColor.opacity(0.12)), in: .capsule)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
    }

    private func tabButton(_ tab: GoldenHourTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: GHSpacing.sm) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))

                if selectedTab == tab {
                    Text(tab.title(lang: appLanguage))
                        .font(GHFont.micro)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .foregroundColor(selectedTab == tab ? .ghBgDeep : .ghTextTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                if selectedTab == tab {
                    Capsule(style: .continuous)
                        .fill(accentColor)
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectID(tab.id, in: namespace)
    }
}

@MainActor
private struct RedesignedSettingsView: View {
    @ObservedObject var healthManager: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled: Bool = true
    @AppStorage("dashboardChartStyle") private var dashboardChartStyle: String = DashboardChartStyle.neon.rawValue

    private var activePhase: DayPhase {
        healthManager.currentPhase.visualFallback
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PhaseBackground(phase: healthManager.currentPhase)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: GHSpacing.xl) {
                        header
                        languageSection
                        appearanceSection
                        liveActivitySection
                        aboutSection
                    }
                    .padding(.horizontal, GHSpacing.md)
                    .padding(.top, GHSpacing.xl)
                    .padding(.bottom, GHSpacing.xxl + 84)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        Text(AppTranslation.get("settings", lang: appLanguage))
            .font(GHFont.titleLarge)
            .foregroundColor(.ghTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var languageSection: some View {
        SettingsSectionView(title: AppTranslation.get("language", lang: appLanguage), accentColor: activePhase.accentColor) {
            Picker(AppTranslation.get("language", lang: appLanguage), selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.name).tag(lang.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(activePhase.accentColor)
        }
    }

    private var appearanceSection: some View {
        SettingsSectionView(title: AppTranslation.get("theme", lang: appLanguage), accentColor: activePhase.accentColor) {
            Picker(AppTranslation.get("theme", lang: appLanguage), selection: $appTheme) {
                Text(AppTranslation.get("theme_system", lang: appLanguage)).tag(0)
                Text(AppTranslation.get("theme_dark", lang: appLanguage)).tag(2)
            }
            .pickerStyle(.segmented)

            Divider().overlay(Color.white.opacity(0.12))

            Picker(AppTranslation.get("chart_style", lang: appLanguage), selection: $dashboardChartStyle) {
                ForEach(DashboardChartStyle.allCases) { style in
                    Text(AppTranslation.get(style.titleKey, lang: appLanguage)).tag(style.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(activePhase.accentColor)
        }
    }

    private var liveActivitySection: some View {
        SettingsSectionView(title: AppTranslation.get("live_activities_title", lang: appLanguage), accentColor: activePhase.accentColor) {
            Toggle(isOn: $liveActivitiesEnabled) {
                VStack(alignment: .leading, spacing: GHSpacing.xs) {
                    Text(AppTranslation.get("live_activities_title", lang: appLanguage))
                        .font(GHFont.body)
                        .foregroundColor(.ghTextPrimary)
                    Text(AppTranslation.get("live_activities_desc", lang: appLanguage))
                        .font(GHFont.caption)
                        .foregroundColor(.ghTextTertiary)
                }
            }
            .tint(activePhase.accentColor)
            .onChange(of: liveActivitiesEnabled) { _, newValue in
                if newValue {
                    healthManager.updateLiveActivity()
                } else {
                    healthManager.stopAllActivities()
                }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSectionView(title: AppTranslation.get("about", lang: appLanguage), accentColor: activePhase.accentColor) {
            NavigationLink(destination: AboutView(healthManager: healthManager)) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(activePhase.accentColor)
                        .frame(width: 24)
                    Text(AppTranslation.get("about", lang: appLanguage))
                        .font(GHFont.body)
                        .foregroundColor(.ghTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.ghTextTertiary)
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.vertical, GHSpacing.xs)
            }
        }
    }
}

private struct SettingsSectionView<Content: View>: View {
    let title: String
    let accentColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: GHSpacing.sm) {
            Text(title.uppercased())
                .font(GHFont.micro)
                .tracking(1.5)
                .foregroundColor(.ghTextTertiary)

            VStack(alignment: .leading, spacing: GHSpacing.md) {
                content
            }
            .padding(GHSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ghGlassCard(cornerRadius: GHRadius.md, tint: accentColor.opacity(0.08))
        }
    }
}
