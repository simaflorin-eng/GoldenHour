import SwiftUI
import StoreKit
import UIKit

// MARK: - GHDesignSystem

enum GHAwardDesignSystem {
    static let amber = Color(red: 1.0, green: 0.65, blue: 0.10)
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.35)
    static let deepSky = Color(red: 0.055, green: 0.035, blue: 0.025)
    static let ink = Color(red: 0.025, green: 0.018, blue: 0.014)
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.58)
    static let tertiaryText = Color.white.opacity(0.34)

    static let hero = Font.system(size: 70, weight: .ultraLight, design: .rounded)
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let micro = Font.system(size: 11, weight: .bold, design: .rounded)
}

extension DayPhase {
    var ghColor: Color {
        switch visualFallback {
        case .morningPrep: return Color(red: 1.0, green: 0.77, blue: 0.28)
        case .focus: return Color(red: 1.0, green: 0.48, blue: 0.12)
        case .caffeine: return Color(red: 0.64, green: 0.42, blue: 0.22)
        case .afternoon: return Color(red: 0.46, green: 0.70, blue: 0.50)
        case .sunset: return Color(red: 0.84, green: 0.34, blue: 0.55)
        case .idle: return GHAwardDesignSystem.amber
        }
    }

    var arcColors: [Color] {
        switch visualFallback {
        case .morningPrep:
            return [Color(red: 1.0, green: 0.88, blue: 0.42), Color(red: 1.0, green: 0.58, blue: 0.20)]
        case .focus:
            return [Color(red: 1.0, green: 0.68, blue: 0.18), Color(red: 1.0, green: 0.32, blue: 0.08)]
        case .caffeine:
            return [Color(red: 0.72, green: 0.48, blue: 0.26), Color(red: 0.42, green: 0.24, blue: 0.12)]
        case .afternoon:
            return [Color(red: 0.60, green: 0.82, blue: 0.58), Color(red: 0.24, green: 0.52, blue: 0.38)]
        case .sunset:
            return [Color(red: 0.95, green: 0.42, blue: 0.58), Color(red: 0.42, green: 0.30, blue: 0.74)]
        case .idle:
            return [GHAwardDesignSystem.amber, GHAwardDesignSystem.deepSky]
        }
    }

    var iconName: String? {
        switch self {
        case .morningPrep: return "sunrise.fill"
        case .focus: return "brain.head.profile"
        case .caffeine: return "cup.and.saucer.fill"
        case .afternoon: return "sun.and.horizon.fill"
        case .sunset: return "sunset.fill"
        case .idle: return "moon.stars.fill"
        }
    }
}

extension Color {
    static func skyGradient(for phase: DayPhase) -> [Color] {
        switch phase.visualFallback {
        case .morningPrep:
            return [Color(red: 0.22, green: 0.11, blue: 0.03), Color(red: 0.66, green: 0.30, blue: 0.08), GHAwardDesignSystem.deepSky]
        case .focus:
            return [Color(red: 0.28, green: 0.10, blue: 0.015), Color(red: 0.55, green: 0.20, blue: 0.03), GHAwardDesignSystem.ink]
        case .caffeine:
            return [Color(red: 0.16, green: 0.09, blue: 0.045), Color(red: 0.31, green: 0.18, blue: 0.08), GHAwardDesignSystem.ink]
        case .afternoon:
            return [Color(red: 0.04, green: 0.16, blue: 0.11), Color(red: 0.13, green: 0.30, blue: 0.22), GHAwardDesignSystem.ink]
        case .sunset:
            return [Color(red: 0.19, green: 0.05, blue: 0.11), Color(red: 0.27, green: 0.18, blue: 0.42), GHAwardDesignSystem.ink]
        case .idle:
            return [Color(red: 0.08, green: 0.06, blue: 0.09), GHAwardDesignSystem.deepSky, .black]
        }
    }
}

struct GHAwardPhaseItem: Identifiable {
    var id: DayPhase { phase }
    let phase: DayPhase
    let name: String
    let start: Date
    let end: Date
    let timeRangeString: String

    var iconName: String {
        phase.iconName ?? phase.icon
    }
}

// MARK: - GHPhaseRing

struct GHPhaseRing: View {
    let phases: [GHAwardPhaseItem]
    let currentPhase: DayPhase
    let now: Date

    private let lineWidth: CGFloat = 22

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = (size - lineWidth - 14) / 2
            let metrics = ringMetrics

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.045), lineWidth: lineWidth)
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(metrics.segments) { segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            AngularGradient(colors: segment.phase.arcColors, center: .center),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .opacity(segment.phase == currentPhase ? 1 : 0.48)
                        .shadow(color: segment.phase == currentPhase ? segment.phase.ghColor.opacity(0.36) : .clear, radius: 16)
                        .frame(width: radius * 2, height: radius * 2)

                    phaseGlyph(segment.phase)
                        .position(segment.iconPosition(in: proxy.size, radius: radius))
                }

                needle(angle: metrics.needleAngle, radius: radius, size: proxy.size)

                VStack(spacing: 8) {
                    Text(currentPhaseTitle)
                        .font(GHAwardDesignSystem.micro)
                        .tracking(2.2)
                        .foregroundStyle(currentPhase.ghColor)
                    Text(now.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 32, weight: .thin, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Astronomical phase clock, current phase \(currentPhaseTitle)")
    }

    private var ringMetrics: (segments: [RingSegment], needleAngle: Double) {
        guard let dayStart = phases.first?.start, let dayEnd = phases.last?.end else {
            return ([], 0)
        }

        let total = max(1, dayEnd.timeIntervalSince(dayStart))
        let gap = 0.006
        let segments = phases.map { item in
            let start = max(0, min(1, item.start.timeIntervalSince(dayStart) / total))
            let end = max(0, min(1, item.end.timeIntervalSince(dayStart) / total))
            return RingSegment(phase: item.phase, start: start + gap, end: max(start + gap, end - gap))
        }
        let nowRatio = max(0, min(1, now.timeIntervalSince(dayStart) / total))
        return (segments, -90 + 360 * nowRatio)
    }

    private var currentPhaseTitle: String {
        currentPhase.rawValue.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    private func phaseGlyph(_ phase: DayPhase) -> some View {
        Image(systemName: phase.iconName ?? phase.icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(phase == currentPhase ? GHAwardDesignSystem.ink : phase.ghColor)
            .frame(width: 30, height: 30)
            .background(phase == currentPhase ? phase.ghColor : Color.white.opacity(0.08), in: Circle())
    }

    private func needle(angle: Double, radius: CGFloat, size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radians = angle * .pi / 180
        let end = CGPoint(
            x: center.x + cos(radians) * (radius - 18),
            y: center.y + sin(radians) * (radius - 18)
        )

        return ZStack {
            Path { path in
                path.move(to: center)
                path.addLine(to: end)
            }
            .stroke(Color.white.opacity(0.92), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            .shadow(color: currentPhase.ghColor.opacity(0.55), radius: 8)

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .position(center)
        }
    }

    private struct RingSegment: Identifiable {
        var id: DayPhase { phase }
        let phase: DayPhase
        let start: Double
        let end: Double

        func iconPosition(in size: CGSize, radius: CGFloat) -> CGPoint {
            let middle = ((start + end) / 2) * 2 * .pi - (.pi / 2)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            return CGPoint(
                x: center.x + cos(middle) * radius,
                y: center.y + sin(middle) * radius
            )
        }
    }
}

// MARK: - GHDashboardView

@MainActor
struct GHDashboardView: View {
    @EnvironmentObject private var model: HealthKitManager
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    private var visiblePhases: [GHAwardPhaseItem] {
        model.phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .map { item in
                GHAwardPhaseItem(
                    phase: item.phase,
                    name: title(for: item.phase),
                    start: item.start,
                    end: item.end,
                    timeRangeString: "\(item.start.formatted(date: .omitted, time: .shortened)) - \(item.end.formatted(date: .omitted, time: .shortened))"
                )
            }
    }

    var body: some View {
        ZStack {
            GHSkyBackground(phase: model.currentPhase)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    hero

                    GHPhaseRing(
                        phases: visiblePhases,
                        currentPhase: model.currentPhase.visualFallback,
                        now: model.now
                    )
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 14)

                    phasePills
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 112)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Text(model.wakeUpTime.formatted(date: .omitted, time: .shortened))
                .font(GHAwardDesignSystem.hero)
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.74)
                .lineLimit(1)
                .shadow(color: model.currentPhase.visualFallback.ghColor.opacity(0.36), radius: 22, y: 8)

            Text(AppTranslation.get("wake_up_label", lang: appLanguage).uppercased())
                .font(GHAwardDesignSystem.micro)
                .tracking(2.4)
                .foregroundStyle(GHAwardDesignSystem.tertiaryText)

            HStack(spacing: 8) {
                Image(systemName: model.currentPhase.visualFallback.iconName ?? model.currentPhase.visualFallback.icon)
                Text(title(for: model.currentPhase.visualFallback).uppercased())
            }
            .font(GHAwardDesignSystem.micro)
            .tracking(1.4)
            .foregroundStyle(model.currentPhase.visualFallback.ghColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassEffect(.regular.tint(model.currentPhase.visualFallback.ghColor.opacity(0.16)), in: .capsule)
            .padding(.top, 8)
        }
    }

    private var phasePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(visiblePhases) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 7) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(item.name)
                                .font(GHAwardDesignSystem.caption)
                                .lineLimit(1)
                        }
                        Text(item.timeRangeString)
                            .font(GHAwardDesignSystem.micro)
                            .monospacedDigit()
                            .foregroundStyle(GHAwardDesignSystem.secondaryText)
                    }
                    .foregroundStyle(item.phase == model.currentPhase ? GHAwardDesignSystem.ink : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minWidth: 148, alignment: .leading)
                    .background(item.phase == model.currentPhase ? item.phase.ghColor : Color.white.opacity(0.06), in: Capsule(style: .continuous))
                    .glassEffect(.regular.tint(item.phase.ghColor.opacity(item.phase == model.currentPhase ? 0.24 : 0.08)), in: .capsule)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
        }
    }

    private func title(for phase: DayPhase) -> String {
        switch phase {
        case .morningPrep: return AppTranslation.get("morning_prep", lang: appLanguage)
        case .focus: return AppTranslation.get("peak_focus", lang: appLanguage)
        case .caffeine: return AppTranslation.get("caffeine_cutoff", lang: appLanguage)
        case .afternoon: return AppTranslation.get("afternoon_reset", lang: appLanguage)
        case .sunset: return AppTranslation.get("sunset_walk", lang: appLanguage)
        case .idle: return AppTranslation.get("day_complete", lang: appLanguage)
        }
    }
}

private struct GHSkyBackground: View {
    let phase: DayPhase

    var body: some View {
        ZStack {
            MeshGradient(
                width: 2,
                height: 2,
                points: [
                    SIMD2<Float>(0, 0), SIMD2<Float>(1, 0),
                    SIMD2<Float>(0, 1), SIMD2<Float>(1, 1)
                ],
                colors: Color.skyGradient(for: phase)
            )
            .blur(radius: 46)
            .ignoresSafeArea()
            .animation(.spring(response: 1.1, dampingFraction: 0.88), value: phase)

            LinearGradient(
                colors: [.black.opacity(0.08), GHAwardDesignSystem.deepSky.opacity(0.62), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - GHTabBar

private struct GHTabBar: View {
    @Binding var selectedTab: GHAwardTab
    let accentColor: Color
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(GHAwardTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 16, weight: .semibold))
                            if selectedTab == tab {
                                Text(tab.title(lang: appLanguage))
                                    .font(GHAwardDesignSystem.caption)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }
                        }
                        .foregroundStyle(selectedTab == tab ? GHAwardDesignSystem.ink : .white.opacity(0.74))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            if selectedTab == tab {
                                Capsule(style: .continuous)
                                    .fill(accentColor)
                                    .matchedGeometryEffect(id: "selectedAwardTab", in: namespace)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .glassEffectID(tab.id, in: namespace)
                }
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .glassEffect(.regular.tint(accentColor.opacity(0.12)), in: .capsule)
        .shadow(color: .black.opacity(0.30), radius: 24, y: 12)
    }
}

private enum GHAwardTab: String, CaseIterable, Identifiable {
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

// MARK: - GHSettingsView

@MainActor
struct GHSettingsView: View {
    @EnvironmentObject private var model: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled: Bool = true
    @AppStorage("dashboardChartStyle") private var dashboardChartStyle: String = DashboardChartStyle.neon.rawValue

    private var accent: Color {
        model.currentPhase.visualFallback.ghColor
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GHSkyBackground(phase: model.currentPhase)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(AppTranslation.get("settings", lang: appLanguage))
                            .font(GHAwardDesignSystem.title)
                            .foregroundStyle(.white)
                            .padding(.top, 28)

                        settingsPanel(AppTranslation.get("language", lang: appLanguage), icon: "globe") {
                            Picker(AppTranslation.get("language", lang: appLanguage), selection: $appLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.name).tag(lang.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)
                        }

                        settingsPanel(AppTranslation.get("theme", lang: appLanguage), icon: "circle.lefthalf.filled") {
                            Picker(AppTranslation.get("theme", lang: appLanguage), selection: $appTheme) {
                                Text(AppTranslation.get("theme_system", lang: appLanguage)).tag(0)
                                Text(AppTranslation.get("theme_dark", lang: appLanguage)).tag(2)
                            }
                            .pickerStyle(.segmented)

                            Picker(AppTranslation.get("chart_style", lang: appLanguage), selection: $dashboardChartStyle) {
                                ForEach(DashboardChartStyle.allCases) { style in
                                    Text(AppTranslation.get(style.titleKey, lang: appLanguage)).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accent)
                        }

                        settingsPanel(AppTranslation.get("live_activities_title", lang: appLanguage), icon: "sparkles.rectangle.stack.fill") {
                            Toggle(isOn: $liveActivitiesEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(AppTranslation.get("live_activities_title", lang: appLanguage))
                                        .font(GHAwardDesignSystem.headline)
                                        .foregroundStyle(.white)
                                    Text(AppTranslation.get("live_activities_desc", lang: appLanguage))
                                        .font(GHAwardDesignSystem.caption)
                                        .foregroundStyle(GHAwardDesignSystem.secondaryText)
                                }
                            }
                            .tint(accent)
                            .onChange(of: liveActivitiesEnabled) { _, newValue in
                                if newValue {
                                    model.updateLiveActivity()
                                } else {
                                    model.stopAllActivities()
                                }
                            }
                        }

                        settingsPanel(AppTranslation.get("about", lang: appLanguage), icon: "info.circle.fill") {
                            NavigationLink {
                                AboutView(healthManager: model)
                            } label: {
                                HStack {
                                    Text(AppTranslation.get("about", lang: appLanguage))
                                        .font(GHAwardDesignSystem.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 112)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsPanel<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GHAwardDesignSystem.ink)
                    .frame(width: 30, height: 30)
                    .background(accent, in: Circle())

                Text(title.uppercased())
                    .font(GHAwardDesignSystem.micro)
                    .tracking(1.6)
                    .foregroundStyle(GHAwardDesignSystem.tertiaryText)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(accent.opacity(0.08)), in: .rect(cornerRadius: 24))
    }
}

@MainActor
struct GHAwardRootView: View {
    @EnvironmentObject private var model: HealthKitManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.requestReview) private var requestReview
    @State private var selectedTab: GHAwardTab = .dashboard
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
            switch selectedTab {
            case .dashboard:
                GHDashboardView()
            case .settings:
                GHSettingsView()
            }

            GHTabBar(selectedTab: $selectedTab, accentColor: model.currentPhase.visualFallback.ghColor)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .onAppear {
            guard !didConfigureManagers else { return }
            didConfigureManagers = true
            model.connectLocationManager(locationManager)
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
