// ============================================================
// GOLDEN HOUR — REDESIGN v3 "Immersive B"
// Adapted to this project model: HealthKitManager + DayPhase
// ============================================================

import SwiftUI
import StoreKit
import UIKit

// MARK: - Design Tokens

extension Color {
    static let ghBg = Color(red: 0.035, green: 0.030, blue: 0.040)

    static func phaseGlow(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 0.85, green: 0.55, blue: 0.05)
        case .focus: return Color(red: 0.90, green: 0.38, blue: 0.08)
        case .caffeine: return Color(red: 0.72, green: 0.26, blue: 0.10)
        case .afternoon: return Color(red: 0.15, green: 0.55, blue: 0.40)
        case .sunset: return Color(red: 0.55, green: 0.18, blue: 0.62)
        case .idle: return Color(red: 0.80, green: 0.45, blue: 0.05)
        }
    }

    static func phaseAccent(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 1.00, green: 0.78, blue: 0.25)
        case .focus: return Color(red: 1.00, green: 0.55, blue: 0.18)
        case .caffeine: return Color(red: 0.95, green: 0.40, blue: 0.15)
        case .afternoon: return Color(red: 0.30, green: 0.82, blue: 0.60)
        case .sunset: return Color(red: 0.82, green: 0.45, blue: 0.95)
        case .idle: return Color(red: 1.00, green: 0.65, blue: 0.18)
        }
    }

    static func chipColor(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 0.80, green: 0.55, blue: 0.10)
        case .focus: return Color(red: 0.85, green: 0.35, blue: 0.08)
        case .caffeine: return Color(red: 0.75, green: 0.28, blue: 0.10)
        case .afternoon: return Color(red: 0.18, green: 0.62, blue: 0.42)
        case .sunset: return Color(red: 0.58, green: 0.20, blue: 0.65)
        case .idle: return Color(red: 0.75, green: 0.40, blue: 0.08)
        }
    }
}

enum GHF {
    static let heroTime = Font.system(size: 88, weight: .ultraLight, design: .rounded)
    static let wakeLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    static let remaining = Font.system(size: 30, weight: .light, design: .rounded)
    static let remainLabel = Font.system(size: 10, weight: .medium, design: .rounded)
    static let phasePill = Font.system(size: 10, weight: .semibold, design: .rounded)
    static let chipLabel = Font.system(size: 11, weight: .medium, design: .rounded)
    static let tabLabel = Font.system(size: 12, weight: .regular, design: .rounded)
    static let progTime = Font.system(size: 10, weight: .regular, design: .rounded)
}

private struct V3PhaseItem: Identifiable {
    var id: DayPhase { phase }
    let phase: DayPhase
    let name: String
    let start: Date
    let end: Date

    var timeRangeString: String {
        "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}

private extension DayPhase {
    var v3IconName: String {
        switch self {
        case .morningPrep: return "sunrise.fill"
        case .focus: return "brain.head.profile"
        case .caffeine: return "cup.and.saucer.fill"
        case .afternoon: return "sun.and.horizon.fill"
        case .sunset: return "sunset.fill"
        case .idle: return "moon.stars.fill"
        }
    }

    var v3TranslationKey: String {
        switch self {
        case .morningPrep: return "morning_prep"
        case .focus: return "peak_focus"
        case .caffeine: return "caffeine_cutoff"
        case .afternoon: return "afternoon_reset"
        case .sunset: return "sunset_walk"
        case .idle: return "day_complete"
        }
    }
}

// MARK: - Root View

@MainActor
struct GHV3RootView: View {
    @EnvironmentObject private var model: HealthKitManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.requestReview) private var requestReview
    @State private var selectedTab = 0
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

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if selectedTab == 0 {
                    V3ImmersiveDashboardView()
                } else {
                    V3ImmersiveSettingsView()
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)

            GHTabBarView(selectedTab: $selectedTab)
        }
        .onAppear {
            guard !didConfigureManagers else { return }
            didConfigureManagers = true
            model.connectLocationManager(locationManager)
            registerLaunchAndScheduleReviewPrompt()
        }
        .alert(AppTranslation.get("review_prompt_title", lang: appLanguage), isPresented: $showReviewPrompt) {
            Button(AppTranslation.get("review_prompt_cta", lang: appLanguage)) {
                reviewPromptCompleted = true
                openReviewPage()
            }
            Button(AppTranslation.get("review_prompt_later", lang: appLanguage), role: .cancel) {}
        } message: {
            Text(AppTranslation.get("review_prompt_message", lang: appLanguage))
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
        return now.timeIntervalSince1970 - reviewPromptLastShownAt >= reviewPromptCooldown
    }

    private func openReviewPage() {
        guard let appStoreReviewURL, UIApplication.shared.canOpenURL(appStoreReviewURL) else {
            requestReview()
            return
        }
        UIApplication.shared.open(appStoreReviewURL)
    }
}

// MARK: - Dashboard View

@MainActor
private struct V3ImmersiveDashboardView: View {
    @EnvironmentObject private var model: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var glowPulse = false

    private var activePhase: DayPhase {
        model.currentPhase.visualFallback
    }

    private var wakeStr: String {
        model.wakeUpTime.formatted(date: .omitted, time: .shortened)
    }

    private var dayEndTime: Date {
        phaseItems.last?.end ?? model.sunsetWalkEnd
    }

    private var dayProgress: Double {
        let total = dayEndTime.timeIntervalSince(model.wakeUpTime)
        guard total > 0 else { return 0 }
        return min(max(Date().timeIntervalSince(model.wakeUpTime) / total, 0), 1)
    }

    private var phaseItems: [V3PhaseItem] {
        model.phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .map { item in
                V3PhaseItem(
                    phase: item.phase,
                    name: AppTranslation.get(item.phase.v3TranslationKey, lang: appLanguage),
                    start: item.start,
                    end: item.end
                )
            }
    }

    private var phasePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.phaseAccent(activePhase))
                .frame(width: 5, height: 5)
                .shadow(color: Color.phaseAccent(activePhase), radius: 4)
            Text(AppTranslation.get(activePhase.v3TranslationKey, lang: appLanguage).uppercased())
                .font(GHF.phasePill)
                .tracking(2.5)
                .foregroundColor(Color.phaseAccent(activePhase))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.phaseAccent(activePhase).opacity(0.12))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.phaseAccent(activePhase).opacity(0.28), lineWidth: 0.5)
                )
        )
    }

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 760
            let topInset = geo.safeAreaInsets.top + (compact ? 4 : 10)
            let heroSize = min(compact ? 68 : 82, max(58, geo.size.width * 0.21))
            let countdownSize = compact ? 24.0 : 30.0
            let tabClearance = geo.safeAreaInsets.bottom + 92

            ZStack {
                GHSkyBackground(phase: model.currentPhase, pulse: $glowPulse)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Color.clear.frame(height: topInset)

                    phasePill

                    Color.clear.frame(height: compact ? 10 : 16)

                    Text(wakeStr)
                        .font(.system(size: heroSize, weight: .ultraLight, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.phaseGlow(activePhase).opacity(0.6), radius: compact ? 18 : 24, x: 0, y: 8)
                        .monospacedDigit()
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)

                    Text("ORA DE TREZIRE")
                        .font(GHF.wakeLabel)
                        .tracking(2.5)
                        .foregroundColor(Color.white.opacity(0.25))

                    Color.clear.frame(height: compact ? 18 : 26)

                    if model.currentPhase != .idle {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(model.currentPhaseEndTime, style: .timer)
                                .font(.system(size: countdownSize, weight: .light, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.88))
                                .monospacedDigit()
                            Text("RĂMAS ÎN FAZĂ")
                                .font(GHF.remainLabel)
                                .tracking(1.5)
                                .foregroundColor(Color.white.opacity(0.28))
                        }
                    }

                    Color.clear.frame(height: compact ? 18 : 24)

                    GHProgressLine(
                        progress: dayProgress,
                        phase: activePhase,
                        wakeTime: model.wakeUpTime,
                        endTime: dayEndTime
                    )
                    .padding(.horizontal, compact ? 18 : 28)

                    Spacer(minLength: compact ? 18 : 32)

                    GHPhaseChips(phases: phaseItems, currentPhase: model.currentPhase)

                    Color.clear.frame(height: tabClearance)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Sky Background

private struct GHSkyBackground: View {
    let phase: DayPhase
    @Binding var pulse: Bool

    var body: some View {
        ZStack {
            Color.ghBg

            RadialGradient(
                colors: [
                    Color.phaseGlow(phase).opacity(pulse ? 0.38 : 0.28),
                    Color.phaseGlow(phase).opacity(0.08),
                    Color.clear
                ],
                center: .init(x: 0.5, y: pulse ? -0.05 : 0.0),
                startRadius: 0,
                endRadius: 520
            )
            .animation(.easeInOut(duration: 3), value: pulse)

            RadialGradient(
                colors: [Color.phaseGlow(phase).opacity(0.12), Color.clear],
                center: .init(x: 0.85, y: 1.1),
                startRadius: 0,
                endRadius: 300
            )

            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.55)],
                center: .center,
                startRadius: 100,
                endRadius: 420
            )
        }
    }
}

// MARK: - Progress Line

private struct GHProgressLine: View {
    let progress: Double
    let phase: DayPhase
    let wakeTime: Date
    let endTime: Date

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 2)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.phaseGlow(phase).opacity(0.6), Color.phaseAccent(phase)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 2)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.white.opacity(0.6), radius: 5)
                        .offset(x: geo.size.width * CGFloat(progress) - 4)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack {
                Text(wakeTime.formatted(date: .omitted, time: .shortened))
                    .font(GHF.progTime)
                    .foregroundColor(Color.white.opacity(0.22))
                    .monospacedDigit()
                Spacer()
                Text(endTime.formatted(date: .omitted, time: .shortened))
                    .font(GHF.progTime)
                    .foregroundColor(Color.white.opacity(0.22))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Phase Chips

private struct GHPhaseChips: View {
    let phases: [V3PhaseItem]
    let currentPhase: DayPhase

    var body: some View {
        HStack(spacing: 7) {
            ForEach(phases) { phase in
                let isCurrent = phase.phase == currentPhase
                GHPhaseChip(
                    phase: phase,
                    isCurrent: isCurrent,
                    isPast: phase.end < Date()
                )
                .frame(maxWidth: isCurrent ? .infinity : 38)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 4)
    }
}

private struct GHPhaseChip: View {
    let phase: V3PhaseItem
    let isCurrent: Bool
    let isPast: Bool

    var body: some View {
        HStack(spacing: 5) {
            if isCurrent {
                Circle()
                    .fill(Color.chipColor(phase.phase))
                    .frame(width: 5, height: 5)
                    .shadow(color: Color.chipColor(phase.phase), radius: 4)

                Text(phase.name)
                    .font(GHF.chipLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(.white)

                Text("·")
                    .font(GHF.chipLabel)
                    .foregroundColor(Color.chipColor(phase.phase).opacity(0.7))
                Text("ACUM")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.0)
                    .foregroundColor(Color.chipColor(phase.phase))
                    .lineLimit(1)
            } else {
                Image(systemName: phase.phase.v3IconName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isPast ? Color.white.opacity(0.24) : Color.white.opacity(0.50))
            }
        }
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isCurrent ? 12 : 0)
        .background(
            Capsule()
                .fill(isCurrent ? Color.chipColor(phase.phase).opacity(0.16) : Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isCurrent ? Color.chipColor(phase.phase).opacity(0.4) : Color.white.opacity(0.07),
                            lineWidth: 0.5
                        )
                )
        )
        .opacity(isPast && !isCurrent ? 0.55 : 1.0)
        .accessibilityLabel(phase.name)
    }
}

// MARK: - Tab Bar

private struct GHTabBarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 6) {
            tabBtn(index: 0, icon: "clock", activeIcon: "clock.fill", label: "Panou")
            tabBtn(index: 1, icon: "gearshape", activeIcon: "gearshape.fill", label: "Setări")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [Color.ghBg, Color.ghBg.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 120)
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private func tabBtn(index: Int, icon: String, activeIcon: String, label: String) -> some View {
        let active = selectedTab == index
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: active ? activeIcon : icon)
                    .font(.system(size: 15, weight: active ? .medium : .light))
                Text(label)
                    .font(GHF.tabLabel)
            }
            .foregroundColor(active ? Color(red: 0.88, green: 0.55, blue: 0.12) : Color.white.opacity(0.3))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(active ? Color(red: 0.88, green: 0.55, blue: 0.12).opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                active ? Color(red: 0.88, green: 0.55, blue: 0.12).opacity(0.28) : Color.white.opacity(0.07),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

@MainActor
private struct V3ImmersiveSettingsView: View {
    @EnvironmentObject private var model: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("dashboardChartStyle") private var dashboardChartStyle: String = DashboardChartStyle.neon.rawValue
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.05, blue: 0.08), Color(red: 0.04, green: 0.03, blue: 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        Text(AppTranslation.get("settings", lang: appLanguage))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 60)

                        settingsSection(title: AppTranslation.get("language", lang: appLanguage)) {
                            Picker(AppTranslation.get("language", lang: appLanguage), selection: $appLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.name).tag(lang.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(red: 0.88, green: 0.55, blue: 0.12))
                            .padding(16)
                        }

                        settingsSection(title: AppTranslation.get("theme", lang: appLanguage)) {
                            Picker(AppTranslation.get("theme", lang: appLanguage), selection: $appTheme) {
                                Text(AppTranslation.get("theme_system", lang: appLanguage)).tag(0)
                                Text(AppTranslation.get("theme_dark", lang: appLanguage)).tag(2)
                            }
                            .pickerStyle(.segmented)
                            .padding(16)
                        }

                        settingsSection(title: AppTranslation.get("chart_style", lang: appLanguage)) {
                            Picker(AppTranslation.get("chart_style", lang: appLanguage), selection: $dashboardChartStyle) {
                                ForEach(DashboardChartStyle.allCases) { style in
                                    Text(AppTranslation.get(style.titleKey, lang: appLanguage)).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color(red: 0.88, green: 0.55, blue: 0.12))
                            .padding(16)
                        }

                        settingsSection(title: AppTranslation.get("live_activities_title", lang: appLanguage)) {
                            toggleRow(
                                icon: "clock.badge",
                                label: AppTranslation.get("live_activities_title", lang: appLanguage),
                                isOn: $liveActivitiesEnabled,
                                caption: AppTranslation.get("live_activities_desc", lang: appLanguage)
                            )
                            .onChange(of: liveActivitiesEnabled) { _, newValue in
                                if newValue {
                                    model.updateLiveActivity()
                                } else {
                                    model.stopAllActivities()
                                }
                            }
                        }

                        settingsSection(title: AppTranslation.get("about", lang: appLanguage)) {
                            NavigationLink(destination: AboutView(healthManager: model)) {
                                rowBase(icon: "info.circle", iconColor: .blue) {
                                    Text(AppTranslation.get("about", lang: appLanguage))
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.22))
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundColor(Color.white.opacity(0.28))

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
                    )
            )
        }
    }

    @ViewBuilder
    private func rowBase<Content: View>(icon: String, iconColor: Color = Color(red: 0.88, green: 0.55, blue: 0.12), @ViewBuilder label: () -> Content) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            label()
        }
        .padding(16)
    }

    @ViewBuilder
    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            rowBase(icon: icon) {
                Text(label)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: isOn)
                    .tint(Color(red: 0.88, green: 0.55, blue: 0.12))
                    .labelsHidden()
            }
            if let caption {
                Text(caption)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.28))
                    .padding(.leading, 62)
                    .padding(.bottom, 14)
            }
        }
    }
}
