import SwiftUI

@MainActor
struct DashboardView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    private var activePhase: DayPhase {
        healthManager.currentPhase.visualFallback
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PhaseBackground(phase: healthManager.currentPhase)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GHSpacing.lg) {
                        hero
                        timelineProgress
                        phaseCards
                    }
                    .padding(.horizontal, GHSpacing.md)
                    .padding(.top, GHSpacing.lg)
                    .padding(.bottom, GHSpacing.xxl + 84)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var hero: some View {
        VStack(spacing: GHSpacing.xs) {
            Text(currentPhaseTitle.uppercased())
                .font(GHFont.micro)
                .tracking(2.5)
                .foregroundColor(activePhase.accentColor)
                .padding(.horizontal, GHSpacing.md)
                .padding(.vertical, GHSpacing.xs)
                .background(activePhase.accentColor.opacity(0.15), in: Capsule())

            Text(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened))
                .font(GHFont.hero)
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color(white: 0.85)], startPoint: .top, endPoint: .bottom)
                )
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(AppTranslation.get("wake_up_label", lang: appLanguage).uppercased())
                .font(GHFont.micro)
                .tracking(2)
                .foregroundColor(.ghTextTertiary)

            if healthManager.currentPhase != .idle {
                HStack(spacing: GHSpacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .medium))
                    Text(healthManager.currentPhaseEndTime, style: .timer)
                        .font(GHFont.caption.monospacedDigit())
                }
                .foregroundColor(.ghTextSecondary)
                .padding(.top, GHSpacing.xs)
            }
        }
        .padding(.vertical, GHSpacing.lg)
        .frame(maxWidth: .infinity)
    }

    private var timelineProgress: some View {
        VStack(spacing: GHSpacing.sm) {
            GeometryReader { geo in
                let metrics = timelineMetrics(width: geo.size.width)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(white: 1.0, opacity: 0.08))
                        .frame(height: 6)

                    ForEach(metrics.segments) { segment in
                        Capsule()
                            .fill(segment.phase.accentColor.opacity(segment.phase == activePhase ? 1 : 0.5))
                            .frame(width: segment.width, height: segment.phase == activePhase ? 10 : 6)
                            .offset(x: segment.x)
                    }

                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: activePhase.accentColor, radius: 6, x: 0, y: 0)
                        .offset(x: metrics.markerX - 7)
                }
            }
            .frame(height: 14)

            HStack {
                Text(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened))
                    .font(GHFont.micro)
                    .foregroundColor(.ghTextTertiary)
                Spacer()
                Text(healthManager.sunsetWalkEnd.formatted(date: .omitted, time: .shortened))
                    .font(GHFont.micro)
                    .foregroundColor(.ghTextTertiary)
            }
        }
        .padding(.horizontal, GHSpacing.sm)
        .padding(GHSpacing.md)
        .ghGlassCard(cornerRadius: GHRadius.md, tint: activePhase.accentColor.opacity(0.08))
    }

    private var phaseCards: some View {
        VStack(spacing: GHSpacing.sm) {
            ForEach(phaseItems) { item in
                PhaseCardView(
                    item: item,
                    isCurrent: item.phase == healthManager.currentPhase,
                    isPast: item.end < Date()
                )
            }
        }
    }

    private var phaseItems: [DashboardPhaseItem] {
        healthManager.phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .map { phase in
                DashboardPhaseItem(
                    phase: phase.phase,
                    name: title(for: phase.phase),
                    start: phase.start,
                    end: phase.end,
                    timeRangeString: "\(phase.start.formatted(date: .omitted, time: .shortened)) - \(phase.end.formatted(date: .omitted, time: .shortened))"
                )
            }
    }

    private var currentPhaseTitle: String {
        if healthManager.currentPhase == .idle {
            return AppTranslation.get("day_complete", lang: appLanguage)
        }

        return title(for: activePhase)
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

    private func timelineMetrics(width: CGFloat) -> (segments: [TimelineMetric], markerX: CGFloat) {
        let visiblePhases = healthManager.phases.filter { $0.phase.appearsInPrimaryCharts }
        guard let start = visiblePhases.first?.start, let end = visiblePhases.last?.end else {
            return ([], 0)
        }

        let total = max(1, end.timeIntervalSince(start))
        let segments = visiblePhases.map { item in
            let startRatio = max(0, min(1, item.start.timeIntervalSince(start) / total))
            let endRatio = max(0, min(1, item.end.timeIntervalSince(start) / total))
            return TimelineMetric(
                phase: item.phase,
                x: width * startRatio,
                width: max(10, width * (endRatio - startRatio))
            )
        }
        let markerRatio = max(0, min(1, Date().timeIntervalSince(start) / total))
        return (segments, width * markerRatio)
    }
}

struct PhaseBackground: View {
    let phase: DayPhase

    private let meshPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0.0, 0.0), SIMD2<Float>(1.0, 0.0),
        SIMD2<Float>(0.0, 1.0), SIMD2<Float>(1.0, 1.0)
    ]

    var body: some View {
        ZStack {
            MeshGradient(width: 2, height: 2, points: meshPoints, colors: meshColors)
                .blur(radius: 44)
                .ignoresSafeArea()
                .animation(.spring(response: 1.2, dampingFraction: 0.86), value: phase)

            LinearGradient(
                colors: [.black.opacity(0.12), .ghBgDeep.opacity(0.78), .black.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var meshColors: [Color] {
        let colors = phase.gradientColors
        return [colors[0].opacity(0.92), colors[1].opacity(0.72), colors[2].opacity(0.82), .ghBgDeep]
    }
}

private struct PhaseCardView: View {
    let item: DashboardPhaseItem
    let isCurrent: Bool
    let isPast: Bool
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    var body: some View {
        HStack(spacing: GHSpacing.md) {
            ZStack {
                Circle()
                    .fill(isCurrent ? item.phase.accentColor.opacity(0.25) : Color(white: 1, opacity: 0.06))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .strokeBorder(isCurrent ? item.phase.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )

                Image(systemName: item.phase.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isCurrent ? item.phase.accentColor : .ghTextSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: GHSpacing.sm) {
                    Text(item.name)
                        .font(GHFont.cardTitle)
                        .foregroundColor(isPast ? .ghTextTertiary : .ghTextPrimary)

                    if isCurrent {
                        Text(nowLabel.uppercased())
                            .font(GHFont.micro)
                            .tracking(1.5)
                            .foregroundColor(item.phase.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(item.phase.accentColor.opacity(0.2), in: Capsule())
                    }
                }

                Text(item.timeRangeString)
                    .font(GHFont.caption)
                    .foregroundColor(.ghTextSecondary)
            }

            Spacer()
        }
        .padding(GHSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: GHRadius.md)
                .fill(isCurrent ? item.phase.accentColor.opacity(0.1) : Color(white: 1, opacity: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: GHRadius.md)
                        .strokeBorder(isCurrent ? item.phase.accentColor.opacity(0.3) : Color(white: 1, opacity: 0.06), lineWidth: 1)
                )
        )
        .glassEffect(isCurrent ? .regular.tint(item.phase.accentColor.opacity(0.18)) : .regular, in: .rect(cornerRadius: GHRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.timeRangeString)")
    }

    private var nowLabel: String {
        let translated = AppTranslation.get("now", lang: appLanguage)
        return translated == "now" ? "Now" : translated
    }
}

private struct DashboardPhaseItem: Identifiable {
    var id: DayPhase { phase }
    let phase: DayPhase
    let name: String
    let start: Date
    let end: Date
    let timeRangeString: String
}

private struct TimelineMetric: Identifiable {
    var id: DayPhase { phase }
    let phase: DayPhase
    let x: CGFloat
    let width: CGFloat
}
