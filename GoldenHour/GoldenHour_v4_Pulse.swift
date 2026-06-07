import SwiftUI

// GOLDEN HOUR - REDESIGN v4 "Pulse"
// Active root for the main app target. This file adapts the Pulse UI to the
// existing HealthKitManager + DayPhase model without changing app logic.

extension Color {
    static let pulseDeepBg = Color(red: 0.035, green: 0.028, blue: 0.042)
    static let pulsePanel = Color.white.opacity(0.045)
    static let pulseLine = Color.white.opacity(0.08)
    static let pulseMutedText = Color.white.opacity(0.34)
    static let pulseAmber = Color(red: 0.95, green: 0.70, blue: 0.20)

    static func orbCore(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 1.00, green: 0.82, blue: 0.28)
        case .focus: return Color(red: 1.00, green: 0.52, blue: 0.12)
        case .caffeine: return Color(red: 0.88, green: 0.36, blue: 0.10)
        case .afternoon: return Color(red: 0.22, green: 0.78, blue: 0.55)
        case .sunset: return Color(red: 0.72, green: 0.32, blue: 0.92)
        case .idle: return Color(red: 0.95, green: 0.65, blue: 0.18)
        }
    }

    static func orbMid(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 0.80, green: 0.52, blue: 0.06)
        case .focus: return Color(red: 0.80, green: 0.30, blue: 0.04)
        case .caffeine: return Color(red: 0.68, green: 0.20, blue: 0.04)
        case .afternoon: return Color(red: 0.08, green: 0.52, blue: 0.32)
        case .sunset: return Color(red: 0.45, green: 0.12, blue: 0.68)
        case .idle: return Color(red: 0.70, green: 0.38, blue: 0.04)
        }
    }

    static func orbGlow(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 0.95, green: 0.72, blue: 0.15)
        case .focus: return Color(red: 0.95, green: 0.42, blue: 0.08)
        case .caffeine: return Color(red: 0.80, green: 0.28, blue: 0.06)
        case .afternoon: return Color(red: 0.15, green: 0.70, blue: 0.42)
        case .sunset: return Color(red: 0.60, green: 0.22, blue: 0.85)
        case .idle: return Color(red: 0.85, green: 0.55, blue: 0.10)
        }
    }

    static func bgGlow(_ phase: DayPhase) -> Color {
        switch phase.visualFallback {
        case .morningPrep: return Color(red: 0.55, green: 0.35, blue: 0.02)
        case .focus: return Color(red: 0.55, green: 0.22, blue: 0.02)
        case .caffeine: return Color(red: 0.45, green: 0.15, blue: 0.02)
        case .afternoon: return Color(red: 0.05, green: 0.38, blue: 0.22)
        case .sunset: return Color(red: 0.35, green: 0.08, blue: 0.48)
        case .idle: return Color(red: 0.48, green: 0.25, blue: 0.02)
        }
    }

    static func pulseBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? pulseDeepBg
            : Color(red: 0.985, green: 0.965, blue: 0.925)
    }

    static func pulsePrimaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .white
            : Color(red: 0.10, green: 0.075, blue: 0.05)
    }

    static func pulseSecondaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.34)
            : Color(red: 0.28, green: 0.22, blue: 0.16).opacity(0.62)
    }

    static func pulseSubtleText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.24)
            : Color(red: 0.32, green: 0.24, blue: 0.16).opacity(0.48)
    }

    static func pulseChipFill(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.055)
            : Color.white.opacity(0.78)
    }

    static func pulseChipStroke(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.09)
            : Color.black.opacity(0.14)
    }

    static func pulseTabFill(_ colorScheme: ColorScheme, isSelected: Bool) -> Color {
        if isSelected {
            return pulseAmber.opacity(colorScheme == .dark ? 0.11 : 0.28)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color(red: 0.98, green: 0.93, blue: 0.82)
    }

    static func pulseTabStroke(_ colorScheme: ColorScheme, isSelected: Bool) -> Color {
        if isSelected {
            return pulseAmber.opacity(colorScheme == .dark ? 0.32 : 0.55)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.07)
            : Color.black.opacity(0.16)
    }
}

private func pulseHeroFont(size: CGFloat) -> Font {
    Font.system(size: size, weight: .ultraLight, design: .rounded)
}

private func pulseRemainingLabel(lang: String) -> String {
    switch lang {
    case "ro": return "RAMAS IN FAZA"
    case "fr": return "RESTANT DANS LA PHASE"
    case "de": return "IN PHASE UBRIG"
    case "es": return "RESTANTE EN FASE"
    case "it": return "RIMANE NELLA FASE"
    default: return "REMAINING IN PHASE"
    }
}

private extension DayPhase {
    var pulseTranslationKey: String {
        switch self {
        case .morningPrep: return "morning_prep"
        case .focus: return "peak_focus"
        case .caffeine: return "caffeine_cutoff"
        case .afternoon: return "afternoon_reset"
        case .sunset: return "sunset_walk"
        case .idle: return "idle_phase"
        }
    }

    var pulseInfoTranslationKey: String {
        switch self {
        case .morningPrep: return "about_morning_prep_info"
        case .focus: return "about_focus_info"
        case .caffeine: return "about_caffeine_info"
        case .afternoon: return "about_afternoon_info"
        case .sunset: return "about_sunset_info"
        case .idle: return "about_idle_info"
        }
    }

    func pulseName(lang: String) -> String {
        AppTranslation.get(pulseTranslationKey, lang: lang)
    }

    func pulseInfo(lang: String) -> String {
        AppTranslation.get(pulseInfoTranslationKey, lang: lang)
    }
}

private extension HealthKitManager {
    var pulseDayEndTime: Date {
        sunsetWalkEnd
    }

    var pulseTimeRemainingInPhase: TimeInterval {
        max(0, currentPhaseEndTime.timeIntervalSince(now))
    }

    var pulsePhaseItems: [GHPulsePhaseItem] {
        phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .map { GHPulsePhaseItem(phase: $0.phase, startTime: $0.start, endTime: $0.end) }
    }
}

private struct GHPulsePhaseItem: Identifiable {
    let phase: DayPhase
    let startTime: Date
    let endTime: Date

    var id: String { "\(phase.rawValue)-\(startTime.timeIntervalSince1970)" }
    func name(lang: String) -> String {
        phase.pulseName(lang: lang)
    }

    func chipTitle(lang: String) -> String {
        phase.pulseName(lang: lang)
    }

    var timeRangeString: String {
        "\(Self.timeFormatter.string(from: startTime)) - \(Self.timeFormatter.string(from: endTime))"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}

struct GHRootView: View {
    @State private var selectedTab = 0
    @State private var showProPaywall = false
    @AppStorage("proPaywallLaunchCount") private var proPaywallLaunchCount = 0
    @EnvironmentObject private var model: HealthKitManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var proStore: ProStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if selectedTab == 0 {
                    GHPulseDashboardView()
                        .transition(.opacity)
                } else {
                    GHPulseSettingsView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)

            if !proStore.isProUnlocked {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showProPaywall = true
                        } label: {
                            Text("PRO")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundColor(Color.pulseAmber)
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background(
                                    Capsule()
                                        .fill(Color.pulseAmber.opacity(0.12))
                                        .overlay(Capsule().strokeBorder(Color.pulseAmber.opacity(0.32), lineWidth: 0.75))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 22)
                        .padding(.top, 62)
                    }
                    Spacer()
                }
                .transition(.opacity)
            }

            GHPulseTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
                .environmentObject(proStore)
        }
        .onAppear {
            model.connectLocationManager(locationManager)
            scheduleProPaywallIfNeeded()
        }
        .onChange(of: proStore.isProUnlocked) { _, isUnlocked in
            if isUnlocked {
                showProPaywall = false
            }
        }
    }

    private func scheduleProPaywallIfNeeded() {
        guard !proStore.isProUnlocked else { return }

        proPaywallLaunchCount += 1

        let firstAutomaticPromptLaunch = 3
        guard proPaywallLaunchCount >= firstAutomaticPromptLaunch else { return }

        let launchesSinceFirstPrompt = proPaywallLaunchCount - firstAutomaticPromptLaunch
        if launchesSinceFirstPrompt == 0 || launchesSinceFirstPrompt % 10 == 0 {
            showProPaywall = true
        }
    }
}

private struct GHPulseDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage = "en"
    @EnvironmentObject private var model: HealthKitManager
    @State private var orbPulse = false
    @State private var glowPulse = false
    @State private var appeared = false
    @State private var currentDate = Date()
    @State private var detailPhase: GHPulsePhaseItem?

    private var phase: DayPhase { model.currentPhase }

    private var wakeString: String {
        Self.timeFormatter.string(from: model.wakeUpTime)
    }

    private var remainingString: String {
        let seconds = Int(max(0, model.currentPhaseEndTime.timeIntervalSince(currentDate)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private var dayProgress: Double {
        let total = model.pulseDayEndTime.timeIntervalSince(model.wakeUpTime)
        guard total > 0 else { return 0 }
        return min(max(currentDate.timeIntervalSince(model.wakeUpTime) / total, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            let compactHeight = geo.size.height < 760
            let orbSize: CGFloat = compactHeight ? 152 : 184
            let wakeFontSize: CGFloat = compactHeight ? 62 : 76
            let topGap: CGFloat = max(safeTop + 46, compactHeight ? 84 : 104)

            ZStack {
                GHPulseBackground(phase: phase, glowPulse: glowPulse, colorScheme: colorScheme)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: phase)

                VStack(spacing: 0) {
                    Spacer().frame(height: topGap)

                    GHPulsePhasePill(phase: phase, appLanguage: appLanguage)
                        .frame(height: 30)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .zIndex(2)

                    Spacer().frame(height: compactHeight ? 12 : 16)

                    Text(wakeString)
                        .font(pulseHeroFont(size: wakeFontSize))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pulsePrimaryText(colorScheme), Color.pulsePrimaryText(colorScheme).opacity(0.66)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .monospacedDigit()
                        .minimumScaleFactor(0.82)
                        .lineLimit(1)
                        .frame(height: compactHeight ? 74 : 90)
                        .shadow(color: Color.orbGlow(phase).opacity(0.5), radius: 22, x: 0, y: 5)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .transaction { transaction in
                            transaction.animation = nil
                        }

                    Text(AppTranslation.get("wake_up_label", lang: appLanguage).uppercased())
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .tracking(2.6)
                        .foregroundColor(Color.pulseSubtleText(colorScheme))
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: compactHeight ? 34 : 50)

                    GHPulseOrb(phase: phase, pulse: orbPulse)
                        .frame(width: orbSize, height: orbSize)
                        .scaleEffect(appeared ? 1 : 0.86)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: compactHeight ? 34 : 44)

                    if phase != .idle {
                        VStack(spacing: 4) {
                            Text(remainingString)
                                .font(.system(size: compactHeight ? 24 : 28, weight: .light, design: .rounded).monospacedDigit())
                                .foregroundColor(Color.pulsePrimaryText(colorScheme).opacity(0.86))
                                .contentTransition(.numericText())

                            Text(pulseRemainingLabel(lang: appLanguage))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .tracking(2.4)
                                .foregroundColor(Color.pulseSubtleText(colorScheme))
                        }
                        .opacity(appeared ? 1 : 0)

                        Spacer(minLength: compactHeight ? 10 : 12)
                    } else {
                        Spacer(minLength: compactHeight ? 22 : 28)
                    }

                    GHPulsePhaseChips(
                        phases: model.pulsePhaseItems,
                        currentPhase: phase,
                        appLanguage: appLanguage,
                        onTap: { detailPhase = $0 }
                    )
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: max(safeBottom + 92, 112))
                }
            }
        }
        .onAppear {
            currentDate = Date()
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .sheet(item: $detailPhase) { item in
            GHPulsePhaseDetailSheet(item: item)
                .presentationDetents([.medium])
                .presentationBackground(.ultraThinMaterial)
        }
        .task {
            while !Task.isCancelled {
                currentDate = Date()
                if currentDate >= model.currentPhaseEndTime {
                    model.refresh()
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}

private struct GHPulseOrb: View {
    let phase: DayPhase
    let pulse: Bool

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orbGlow(phase).opacity(pulse ? 0.18 : 0.08), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.72
                        )
                    )
                    .frame(width: size * 1.32, height: size * 1.32)
                    .scaleEffect(pulse ? 1.08 : 0.96)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orbCore(phase).opacity(0.9),
                                Color.orbMid(phase).opacity(0.75),
                                Color.orbMid(phase).opacity(0.4),
                                .clear
                            ],
                            center: .init(x: 0.38, y: 0.32),
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: Color.orbGlow(phase).opacity(pulse ? 0.55 : 0.35), radius: pulse ? 32 : 22, x: 0, y: 6)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.35), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.18
                        )
                    )
                    .frame(width: size * 0.32, height: size * 0.22)
                    .offset(x: -size * 0.13, y: -size * 0.16)
                    .blendMode(.screen)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.orbCore(phase).opacity(0.5), .clear, Color.orbCore(phase).opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                    .frame(width: size, height: size)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.easeInOut(duration: 3.5), value: pulse)
        .animation(.easeInOut(duration: 1.2), value: phase)
    }
}

private struct GHPulseBackground: View {
    let phase: DayPhase
    let glowPulse: Bool
    let colorScheme: ColorScheme

    var body: some View {
        ZStack {
            Color.pulseBackground(colorScheme)

            RadialGradient(
                colors: [
                    Color.bgGlow(phase).opacity(colorScheme == .dark ? (glowPulse ? 0.55 : 0.42) : (glowPulse ? 0.22 : 0.16)),
                    Color.bgGlow(phase).opacity(colorScheme == .dark ? 0.12 : 0.07),
                    .clear
                ],
                center: .init(x: 0.5, y: glowPulse ? -0.05 : 0.0),
                startRadius: 0,
                endRadius: 480
            )

            RadialGradient(
                colors: [Color.bgGlow(phase).opacity(colorScheme == .dark ? 0.18 : 0.08), .clear],
                center: .init(x: 0.5, y: 1.12),
                startRadius: 0,
                endRadius: 320
            )

            RadialGradient(
                colors: [.clear, (colorScheme == .dark ? Color.black.opacity(0.46) : Color.white.opacity(0.24))],
                center: .center,
                startRadius: 120,
                endRadius: 440
            )
        }
    }
}

private struct GHPulsePhasePill: View {
    let phase: DayPhase
    let appLanguage: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.orbGlow(phase))
                .frame(width: 4, height: 4)
                .shadow(color: Color.orbGlow(phase), radius: 3)

            Text(phase.pulseName(lang: appLanguage).uppercased())
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(2.2)
                .foregroundColor(Color.orbGlow(phase))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.orbGlow(phase).opacity(0.10))
                .overlay(Capsule().strokeBorder(Color.orbGlow(phase).opacity(0.28), lineWidth: 0.5))
        )
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 1.2), value: phase)
    }
}

private struct GHPulseProgressLine: View {
    let progress: Double
    let phase: DayPhase
    let wakeTime: Date
    let endTime: Date

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1.5)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orbMid(phase).opacity(0.7), Color.orbGlow(phase)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 1.5)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.orbGlow(phase).opacity(0.8), radius: 5)
                        .offset(x: max(0, min(geo.size.width - 7, geo.size.width * CGFloat(progress) - 3.5)))
                }
                .frame(height: 7)
            }
            .frame(height: 7)

            HStack {
                Text(Self.formatter.string(from: wakeTime))
                Spacer()
                Text(Self.formatter.string(from: endTime))
            }
            .font(.system(size: 9, design: .rounded).monospacedDigit())
            .foregroundColor(Color.white.opacity(0.22))
        }
        .animation(.easeInOut(duration: 1.2), value: phase)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter
    }()
}

private struct GHPulsePhaseChips: View {
    let phases: [GHPulsePhaseItem]
    let currentPhase: DayPhase
    let appLanguage: String
    let onTap: (GHPulsePhaseItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(phases) { item in
                        GHPulseChip(
                            item: item,
                            isCurrent: item.phase == currentPhase,
                            isPast: item.endTime < Date(),
                            appLanguage: appLanguage,
                            onTap: { onTap(item) }
                        )
                        .id(item.phase.rawValue)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
            .onAppear {
                scrollToCurrentPhase(with: proxy, animated: false)
            }
            .onChange(of: currentPhase) { _, _ in
                scrollToCurrentPhase(with: proxy, animated: true)
            }
        }
    }

    private func scrollToCurrentPhase(with proxy: ScrollViewProxy, animated: Bool) {
        guard phases.contains(where: { $0.phase == currentPhase }) else { return }

        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                proxy.scrollTo(currentPhase.rawValue, anchor: .center)
            }
        } else {
            proxy.scrollTo(currentPhase.rawValue, anchor: .center)
        }
    }
}

private struct GHPulseChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: GHPulsePhaseItem
    let isCurrent: Bool
    let isPast: Bool
    let appLanguage: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(isCurrent ? "\(item.chipTitle(lang: appLanguage)) · \(AppTranslation.get("now_label", lang: appLanguage).lowercased())" : item.chipTitle(lang: appLanguage))
                    .font(.system(size: 13, weight: isCurrent ? .semibold : .medium, design: .rounded))
                    .foregroundColor(
                        isCurrent ? Color.orbGlow(item.phase) : Color.pulseSecondaryText(colorScheme).opacity(isPast ? 0.62 : 1)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(item.timeRangeString)
                    .font(.system(size: 10, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundColor(
                        isCurrent ? Color.orbGlow(item.phase).opacity(0.72) : Color.pulseSubtleText(colorScheme).opacity(isPast ? 0.62 : 1)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 13)
            .frame(minWidth: 104)
            .frame(height: 46)
            .background(
                Capsule()
                    .fill(isCurrent ? Color.orbGlow(item.phase).opacity(colorScheme == .dark ? 0.14 : 0.18) : Color.pulseChipFill(colorScheme))
                    .overlay(
                        Capsule().strokeBorder(
                            isCurrent ? Color.orbGlow(item.phase).opacity(0.42) : Color.pulseChipStroke(colorScheme),
                            lineWidth: 0.75
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GHPulseTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage = "en"
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 6) {
            tabButton(0, icon: "clock", activeIcon: "clock.fill", label: AppTranslation.get("dashboard", lang: appLanguage))
            tabButton(1, icon: "gearshape", activeIcon: "gearshape.fill", label: AppTranslation.get("settings", lang: appLanguage))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [Color.pulseBackground(colorScheme), Color.pulseBackground(colorScheme).opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 110)
            .allowsHitTesting(false),
            alignment: .bottom
        )
    }

    private func tabButton(_ index: Int, icon: String, activeIcon: String, label: String) -> some View {
        let isSelected = selectedTab == index

        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? activeIcon : icon)
                    .font(.system(size: 15, weight: isSelected ? .medium : .light))

                Text(label)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
            }
            .foregroundColor(isSelected ? Color.pulseAmber : Color.pulseSecondaryText(colorScheme).opacity(colorScheme == .dark ? 0.72 : 0.95))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pulseTabFill(colorScheme, isSelected: isSelected))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.pulseTabStroke(colorScheme, isSelected: isSelected), lineWidth: 0.75)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GHPulseSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var model: HealthKitManager
    @EnvironmentObject private var proStore: ProStore
    @AppStorage("appLanguage") private var appLanguage = "en"
    @AppStorage("appTheme") private var theme = 0
    @AppStorage("liveActivitiesEnabled") private var liveActivities = true
    @State private var showProPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.pulseBackground(colorScheme), Color.pulseBackground(colorScheme).opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        Text(AppTranslation.get("settings", lang: appLanguage))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color.pulsePrimaryText(colorScheme))
                            .padding(.top, 64)

                        section(AppTranslation.get("language", lang: appLanguage)) {
                            languageRow()
                        }

                        section(AppTranslation.get("theme", lang: appLanguage)) {
                            pickerRow(
                                icon: "circle.lefthalf.filled",
                                label: AppTranslation.get("theme", lang: appLanguage),
                                selection: $theme,
                                options: [
                                    (AppTranslation.get("theme_system", lang: appLanguage), 0),
                                    (AppTranslation.get("theme_dark", lang: appLanguage), 2)
                                ]
                            )
                        }

                        section(AppTranslation.get("live_activities_title", lang: appLanguage)) {
                            if proStore.isProUnlocked {
                                VStack(alignment: .leading, spacing: 0) {
                                    toggleRow(icon: "clock.badge", label: AppTranslation.get("live_activities_title", lang: appLanguage), isOn: $liveActivities)
                                    Text(AppTranslation.get("live_activities_desc", lang: appLanguage))
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(Color.pulseSecondaryText(colorScheme))
                                        .padding(.leading, 58)
                                        .padding(.bottom, 14)
                                }
                            } else {
                                lockedLiveActivityRow()
                            }
                        }

                        if !proStore.isProUnlocked {
                            section(AppTranslation.get("pro_title", lang: appLanguage)) {
                                proPurchaseRow()
                            }
                        }

                        section(AppTranslation.get("about", lang: appLanguage)) {
                            NavigationLink(destination: AboutView(healthManager: model)) {
                                rowBase(icon: "info.circle", color: .blue) {
                                    Text(AppTranslation.get("about", lang: appLanguage))
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(Color.pulsePrimaryText(colorScheme))
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
            .navigationBarHidden(true)
        }
        .onAppear {
            if theme == 1 {
                theme = 0
            }
        }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
                .environmentObject(proStore)
        }
        .onChange(of: liveActivities) { _, isEnabled in
            if isEnabled {
                model.updateLiveActivity()
            } else {
                model.stopAllActivities()
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundColor(Color.pulseSecondaryText(colorScheme))

            VStack(spacing: 0) { content() }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.pulseChipFill(colorScheme))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.pulseChipStroke(colorScheme), lineWidth: 0.5))
                )
        }
    }

    private func rowBase<Content: View>(icon: String, color: Color = .pulseAmber, @ViewBuilder label: () -> Content) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }

            label()
        }
        .padding(16)
    }

    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        rowBase(icon: icon) {
            Text(label)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.pulsePrimaryText(colorScheme))
            Spacer()
            Toggle("", isOn: isOn)
                .tint(Color.pulseAmber)
                .labelsHidden()
        }
    }

    private func lockedLiveActivityRow() -> some View {
        Button {
            showProPaywall = true
        } label: {
            rowBase(icon: "lock.fill", color: Color.pulseAmber) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(AppTranslation.get("live_activities_title", lang: appLanguage))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.pulsePrimaryText(colorScheme))

                        Text("PRO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(Color.pulseAmber)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.pulseAmber.opacity(colorScheme == .dark ? 0.14 : 0.2)))
                    }

                    Text(AppTranslation.get("live_activities_desc", lang: appLanguage))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.pulseSecondaryText(colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.pulseSecondaryText(colorScheme))
            }
        }
        .buttonStyle(.plain)
    }

    private func proPurchaseRow() -> some View {
        Button {
            showProPaywall = true
        } label: {
            rowBase(icon: "sparkles", color: Color.pulseAmber) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(AppTranslation.get("pro_title", lang: appLanguage))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.pulsePrimaryText(colorScheme))
                    Text(AppTranslation.get("pro_settings_detail", lang: appLanguage) + " - " + proStore.displayPrice)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.pulseSecondaryText(colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.pulseSecondaryText(colorScheme))
            }
        }
        .buttonStyle(.plain)
    }

    private func languageRow() -> some View {
        rowBase(icon: "globe") {
            Text(AppTranslation.get("language", lang: appLanguage))
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.pulsePrimaryText(colorScheme))
            Spacer()
            Menu {
                ForEach(AppLanguage.allCases) { language in
                    Button(language.name) {
                        appLanguage = language.rawValue
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(AppLanguage(rawValue: appLanguage)?.name ?? appLanguage.uppercased())
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(Color.pulseAmber)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.pulseAmber.opacity(colorScheme == .dark ? 0.12 : 0.18)))
            }
        }
    }

    private func pickerRow(icon: String, label: String, selection: Binding<Int>, options: [(String, Int)]) -> some View {
        rowBase(icon: icon) {
            Text(label)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.pulsePrimaryText(colorScheme))
            Spacer()

            HStack(spacing: 2) {
                ForEach(options, id: \.1) { option in
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            selection.wrappedValue = option.1
                        }
                    } label: {
                        Text(option.0)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(selection.wrappedValue == option.1 ? Color(red: 0.06, green: 0.04, blue: 0.02) : Color.pulseSecondaryText(colorScheme))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(selection.wrappedValue == option.1 ? Color.pulseAmber : Color.clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Capsule().fill(Color.pulseChipStroke(colorScheme).opacity(colorScheme == .dark ? 0.9 : 0.6)))
        }
    }
}

private struct GHPulsePhaseDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var appLanguage = "en"
    let item: GHPulsePhaseItem

    var body: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(Color.pulseSecondaryText(colorScheme).opacity(0.32))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Image(systemName: item.phase.icon)
                .font(.system(size: 34, weight: .light))
                .foregroundColor(Color.orbGlow(item.phase))
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.orbGlow(item.phase).opacity(0.12)))

            VStack(spacing: 7) {
                Text(item.name(lang: appLanguage))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.pulsePrimaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text(item.timeRangeString)
                    .font(.system(size: 15, weight: .regular, design: .rounded).monospacedDigit())
                    .foregroundColor(Color.orbGlow(item.phase).opacity(0.76))
            }

            Text(item.phase.pulseInfo(lang: appLanguage))
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.pulseSecondaryText(colorScheme).opacity(colorScheme == .dark ? 1 : 0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 26)

            Button {
                dismiss()
            } label: {
                Text(AppTranslation.get("close", lang: appLanguage))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.06, green: 0.04, blue: 0.02))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Capsule().fill(Color.orbGlow(item.phase)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pulseBackground(colorScheme).opacity(0.96))
    }
}
