import SwiftUI
import Charts
import HealthKit
#if canImport(ActivityKit)
import ActivityKit
#endif

enum DashboardChartStyle: String, CaseIterable, Identifiable {
    case neon
    case linear
    case gauge

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .neon: return "chart_style_neon"
        case .linear: return "chart_style_linear"
        case .gauge: return "chart_style_gauge"
        }
    }
}

@MainActor
struct ContentView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @AppStorage("dashboardChartStyle") private var dashboardChartStyle: String = DashboardChartStyle.neon.rawValue
    
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
                    .opacity(colorScheme == .dark ? 0.35 : 0.15)

                dashboardView
            }
        }
    }

    private var selectedChartStyle: DashboardChartStyle {
        DashboardChartStyle(rawValue: dashboardChartStyle) ?? .neon
    }

    private var dashboardView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerView
                
                VStack(spacing: 15) {
                    progressView
                }
                .padding(.vertical, 25)
                .background(.ultraThinMaterial.opacity(0.5))
                .cornerRadius(40)
                .padding(.horizontal)

                VStack(spacing: 0) {
                    TimelineRow(
                        title: AppTranslation.get("morning_prep", lang: appLanguage),
                        subtitle: "\(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened)) - \(healthManager.peakFocusStart.formatted(date: .omitted, time: .shortened))",
                        icon: DayPhase.morningPrep.icon,
                        color: .cyan,
                        isNow: healthManager.currentPhase == .morningPrep,
                        infoKey: "about_morning_prep_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("peak_focus", lang: appLanguage),
                        subtitle: healthManager.peakFocusInterval,
                        icon: DayPhase.focus.icon,
                        color: .orange,
                        isNow: healthManager.currentPhase == .focus,
                        infoKey: "about_focus_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("caffeine_cutoff", lang: appLanguage),
                        subtitle: healthManager.caffeineCutoff,
                        icon: DayPhase.caffeine.icon,
                        color: Color(hexRGB: DayPhase.caffeine.hexColor, fallback: .brown),
                        isNow: healthManager.currentPhase == .caffeine,
                        infoKey: "about_caffeine_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("afternoon_reset", lang: appLanguage),
                        subtitle: healthManager.afternoonInterval,
                        icon: DayPhase.afternoon.icon,
                        color: Color(hexRGB: DayPhase.afternoon.hexColor, fallback: .green),
                        isNow: healthManager.currentPhase == .afternoon,
                        infoKey: "about_afternoon_info"
                    )
                    Divider().background(Color.primary.opacity(0.06)).padding(.horizontal, 20)
                    TimelineRow(
                        title: AppTranslation.get("sunset_walk", lang: appLanguage),
                        subtitle: healthManager.sunsetWalkEnd.formatted(date: .omitted, time: .shortened),
                        icon: DayPhase.sunset.icon,
                        color: .indigo,
                        isNow: healthManager.currentPhase == .sunset,
                        infoKey: "about_sunset_info"
                    )
                }
                .background(.ultraThinMaterial)
                .cornerRadius(40)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private var progressView: some View {
        switch selectedChartStyle {
        case .neon:
            NeonProgressView(healthManager: healthManager, locationManager: locationManager)
        case .linear:
            LinearTimelineProgressView(healthManager: healthManager)
        case .gauge:
            PhaseGaugeView(healthManager: healthManager)
        }
    }

    private var headerView: some View {
        return VStack(spacing: 8) {
            Text(headerBadgeText)
                .font(.system(size: 9, weight: .black))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
            Text(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 80, weight: .ultraLight, design: .rounded))
            Text(AppTranslation.get("wake_up_label", lang: appLanguage).uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.primary.opacity(0.4))
        }
        .padding(.top, 20)
    }

    private var headerBadgeText: String {
        if healthManager.currentPhase == .idle {
            return AppTranslation.get("day_complete", lang: appLanguage).uppercased()
        }

        return AppTranslation.get("legend_\(healthManager.currentPhase.visualFallback.rawValue)", lang: appLanguage).uppercased()
    }
}

struct NeonProgressView: View {
    @ObservedObject var healthManager: HealthKitManager
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 12) { 
            GeometryReader { geo in
                let spacing: CGFloat = 6
                let horizontalPadding: CGFloat = 40 
                let usableWidth = geo.size.width - horizontalPadding - (4 * spacing)
                let thresholds = calculateThresholds()
                
                HStack(spacing: spacing) {
                    NeonSegment(phase: .morningPrep, color: .cyan, width: usableWidth * thresholds.pFocusStart, isActive: healthManager.currentPhase == .morningPrep, progress: calculateInternalProgress(for: .morningPrep))
                    NeonSegment(phase: .focus, color: .orange, width: usableWidth * (thresholds.pFocusEnd - thresholds.pFocusStart), isActive: healthManager.currentPhase == .focus, progress: calculateInternalProgress(for: .focus))
                    NeonSegment(phase: .caffeine, color: Color(hexRGB: DayPhase.caffeine.hexColor, fallback: .brown), width: usableWidth * (thresholds.pCaffeineEnd - thresholds.pFocusEnd), isActive: healthManager.currentPhase == .caffeine, progress: calculateInternalProgress(for: .caffeine))
                    NeonSegment(phase: .afternoon, color: Color(hexRGB: DayPhase.afternoon.hexColor, fallback: .green), width: usableWidth * (thresholds.pSunsetStart - thresholds.pCaffeineEnd), isActive: healthManager.currentPhase == .afternoon, progress: calculateInternalProgress(for: .afternoon))
                    NeonSegment(phase: .sunset, color: .indigo, width: usableWidth * max(0, (1.0 - thresholds.pSunsetStart)), isActive: healthManager.currentPhase == .sunset, progress: calculateInternalProgress(for: .sunset))
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 24)
            
            if healthManager.currentPhase != .idle {
                HStack(spacing: 4) {
                    Image(systemName: "timer").font(.system(size: 10, weight: .bold))
                    Text(healthManager.currentPhaseEndTime, style: .timer).font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.primary.opacity(0.6))
                .padding(.top, 5)
            }
        }
    }

    private func calculateInternalProgress(for phase: DayPhase) -> Double {
        let now = healthManager.now
        if phase == .idle { return 0 }
        
        guard let phaseData = healthManager.phases.first(where: { $0.phase == phase }) else { return 0 }
        let start = phaseData.start
        let end = phaseData.end
        let total = end.timeIntervalSince(start)
        
        return total > 0 ? max(0, min(1.0, now.timeIntervalSince(start) / total)) : 1.0
    }

    private func calculateThresholds() -> BioThresholds {
        // Obținem segmentele direct din array-ul calculat
        guard let p1 = healthManager.phases.first(where: { $0.phase == .morningPrep }),
              let p2 = healthManager.phases.first(where: { $0.phase == .focus }),
              let p3 = healthManager.phases.first(where: { $0.phase == .caffeine }),
              let p4 = healthManager.phases.first(where: { $0.phase == .afternoon }),
              let p5 = healthManager.phases.first(where: { $0.phase == .sunset }) else {
            return BioThresholds(pFocusStart: 0, pFocusEnd: 0, pCaffeineEnd: 0, pSunsetStart: 0)
        }
        
        let start = p1.start
        let end = p5.end
        let total = max(1, end.timeIntervalSince(start))
        
        return BioThresholds(
            pFocusStart: max(0, min(1.0, p2.start.timeIntervalSince(start) / total)),
            pFocusEnd: max(0, min(1.0, p3.start.timeIntervalSince(start) / total)),
            pCaffeineEnd: max(0, min(1.0, p4.start.timeIntervalSince(start) / total)),
            pSunsetStart: max(0, min(1.0, p5.start.timeIntervalSince(start) / total))
        )
    }

    struct BioThresholds {
        let pFocusStart: Double
        let pFocusEnd: Double
        let pCaffeineEnd: Double
        let pSunsetStart: Double
    }
}

struct LinearTimelineProgressView: View {
    @ObservedObject var healthManager: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let metrics = railMetrics(width: geo.size.width)

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(0.035))

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.primary.opacity(0.05))
                                    .frame(height: 1)
                                Spacer(minLength: 0)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 18)

                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 6)
                        .padding(.horizontal, 10)
                        .position(x: geo.size.width / 2, y: metrics.baselineY)

                    ForEach(Array(metrics.segments.enumerated()), id: \.offset) { _, segment in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(segment.phase == healthManager.currentPhase ? activeColor : Color.primary.opacity(0.16))
                            .frame(width: max(10, segment.width), height: segment.height)
                            .position(x: segment.midX, y: metrics.baselineY)
                    }

                    Path { path in
                        path.move(to: CGPoint(x: metrics.markerX, y: geo.size.height - 8))
                        path.addLine(to: CGPoint(x: metrics.markerX, y: metrics.baselineY - metrics.activeHeight - 12))
                    }
                    .stroke(Color.primary.opacity(0.32), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(activeColor)
                        .frame(width: 8, height: metrics.activeHeight + 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
                        )
                        .position(x: metrics.markerX, y: metrics.baselineY)
                }
            }
            .frame(height: 88)

            HStack(alignment: .top) {
                Text(activePhaseTitle)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
                Spacer()
                if let countdownTarget {
                    Text(countdownTarget, style: .timer)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                } else {
                    Text(phasesEndTime)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
            }

            HStack {
                Text(healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(phasesEndTime)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }

    private var activeColor: Color {
        color(for: healthManager.currentPhase.visualFallback)
    }

    private var activePhaseTitle: String {
        if healthManager.currentPhase == .idle {
            return AppTranslation.get("day_complete", lang: appLanguage).uppercased()
        }

        return healthManager.currentPhase.visualFallback.rawValue.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    private var phasesEndTime: String {
        healthManager.phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .last?
            .end
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    private var countdownTarget: Date? {
        healthManager.currentPhase == .idle ? nil : healthManager.currentPhaseEndTime
    }

    private func railMetrics(width: CGFloat) -> (segments: [RailSegment], markerX: CGFloat, baselineY: CGFloat, activeHeight: CGFloat) {
        let phases = healthManager.phases
            .filter { $0.phase.appearsInPrimaryCharts }
        guard let start = phases.first?.start, let end = phases.last?.end else {
            return ([], 0, 48, 20)
        }

        let total = max(1, end.timeIntervalSince(start))
        let horizontalInset: CGFloat = 10
        let contentWidth = max(1, width - (horizontalInset * 2))
        let baselineY: CGFloat = 46
        let heights: [DayPhase: CGFloat] = [
            .morningPrep: 26,
            .focus: 42,
            .caffeine: 30,
            .afternoon: 20,
            .sunset: 16,
            .idle: 12
        ]

        let segments: [RailSegment] = phases.map { phase in
            let startRatio = CGFloat(max(0, min(1, phase.start.timeIntervalSince(start) / total)))
            let endRatio = CGFloat(max(0, min(1, phase.end.timeIntervalSince(start) / total)))
            let startX = horizontalInset + (contentWidth * startRatio)
            let endX = horizontalInset + (contentWidth * endRatio)
            let height = heights[phase.phase] ?? 18

            return RailSegment(
                phase: phase.phase,
                startX: startX,
                endX: endX,
                midX: (startX + endX) / 2,
                width: max(10, endX - startX),
                height: height,
                color: color(for: phase.phase)
            )
        }

        let markerRatio = CGFloat(max(0, min(1, Date().timeIntervalSince(start) / total)))
        let markerX = horizontalInset + (contentWidth * markerRatio)
        let activeHeight = segments.first(where: { markerX >= $0.startX && markerX <= $0.endX })?.height ?? 20

        return (segments, markerX, baselineY, activeHeight)
    }

    private func color(for phase: DayPhase) -> Color {
        Color(hexRGB: phase.hexColor, fallback: fallbackColor(for: phase))
    }

    private func fallbackColor(for phase: DayPhase) -> Color {
        switch phase {
        case .morningPrep: return .cyan
        case .focus: return .orange
        case .caffeine: return .brown
        case .afternoon: return .green
        case .sunset: return .indigo
        case .idle: return .purple
        }
    }

    private struct RailSegment {
        let phase: DayPhase
        let startX: CGFloat
        let endX: CGFloat
        let midX: CGFloat
        let width: CGFloat
        let height: CGFloat
        let color: Color
    }
}

struct PhaseGaugeView: View {
    @ObservedObject var healthManager: HealthKitManager
    @AppStorage("appLanguage") private var appLanguage: String = "en"

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let width = geo.size.width
                let lineWidth = min(20, width * 0.08)
                let radius = (width - lineWidth - 12) / 2
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height - 18)
                let metrics = gaugeMetrics()

                ZStack {
                    GaugeArc(startAngle: .degrees(-180), endAngle: .degrees(0))
                        .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    ForEach(Array(metrics.segments.enumerated()), id: \.offset) { _, segment in
                        GaugeArc(startAngle: segment.startAngle, endAngle: segment.endAngle)
                            .stroke(segment.color.opacity(segment.phase == healthManager.currentPhase ? 0.98 : 0.5), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            .shadow(color: segment.phase == healthManager.currentPhase ? segment.color.opacity(0.35) : .clear, radius: 8)
                    }

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(on: radius - 22, angle: metrics.needleAngle, center: center))
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.white, activeColor.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .shadow(color: activeColor.opacity(0.35), radius: 8)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white, activeColor.opacity(0.9)],
                                center: .center,
                                startRadius: 1,
                                endRadius: lineWidth
                            )
                        )
                        .frame(width: lineWidth * 0.82, height: lineWidth * 0.82)
                        .position(center)
                        .shadow(color: activeColor.opacity(0.4), radius: 10)
                }
            }
            .frame(height: 138)

            VStack(spacing: 6) {
                Text(activePhaseTitle)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary)
                    .tracking(1.4)

                if let countdownTarget {
                    Text(countdownTarget, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                } else {
                    Text(visiblePhasesEndTime)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                }

                Text(timeRangeLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack {
                gaugeEdgeLabel(
                    title: healthManager.wakeUpTime.formatted(date: .omitted, time: .shortened),
                    icon: "sunrise.fill"
                )
                Spacer()
                gaugeEdgeLabel(
                    title: visiblePhasesEndTime,
                    icon: "moon.stars.fill"
                )
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 10)
    }

    private func gaugeMetrics() -> (segments: [GaugeSegment], needleAngle: Angle) {
        let phases = healthManager.phases
            .filter { $0.phase.appearsInPrimaryCharts }
        guard let start = phases.first?.start, let end = phases.last?.end else {
            return ([], .degrees(-180))
        }

        let total = max(1, end.timeIntervalSince(start))
        let markerRatio = max(0, min(1, Date().timeIntervalSince(start) / total))
        let segments = phases.map { phase in
            let startRatio = max(0, min(1, phase.start.timeIntervalSince(start) / total))
            let endRatio = max(0, min(1, phase.end.timeIntervalSince(start) / total))
            return GaugeSegment(
                phase: phase.phase,
                startAngle: angle(for: startRatio),
                endAngle: angle(for: endRatio),
                color: Color(hexRGB: phase.phase.hexColor, fallback: fallbackColor(for: phase.phase))
            )
        }

        return (segments, angle(for: markerRatio))
    }

    private var activeColor: Color {
        let phase = healthManager.currentPhase.visualFallback
        return Color(hexRGB: phase.hexColor, fallback: fallbackColor(for: phase))
    }

    private var activePhaseTitle: String {
        if healthManager.currentPhase == .idle {
            return AppTranslation.get("day_complete", lang: appLanguage).uppercased()
        }

        return healthManager.currentPhase.visualFallback.rawValue.replacingOccurrences(of: "_", with: " ").uppercased()
    }

    private var timeRangeLabel: String {
        let targetPhase = healthManager.currentPhase.visualFallback
        guard let phase = healthManager.phases.first(where: { $0.phase == targetPhase }) else {
            return ""
        }

        return "\(phase.start.formatted(date: .omitted, time: .shortened)) - \(phase.end.formatted(date: .omitted, time: .shortened))"
    }

    private var visiblePhasesEndTime: String {
        healthManager.phases
            .filter { $0.phase.appearsInPrimaryCharts }
            .last?
            .end
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    private var countdownTarget: Date? {
        healthManager.currentPhase == .idle ? nil : healthManager.currentPhaseEndTime
    }

    private func angle(for ratio: Double) -> Angle {
        .degrees(-180 + (180 * ratio))
    }

    private func point(on radius: CGFloat, angle: Angle, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + CGFloat(cos(angle.radians)) * radius,
            y: center.y + CGFloat(sin(angle.radians)) * radius
        )
    }

    private func fallbackColor(for phase: DayPhase) -> Color {
        switch phase {
        case .morningPrep: return .cyan
        case .focus: return .orange
        case .caffeine: return .brown
        case .afternoon: return .green
        case .sunset: return .indigo
        case .idle: return .purple
        }
    }

    private struct GaugeSegment {
        let phase: DayPhase
        let startAngle: Angle
        let endAngle: Angle
        let color: Color
    }

    @ViewBuilder
    private func gaugeEdgeLabel(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.secondary)
    }
}

struct GaugeArc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: min(rect.width, rect.height * 2) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct NeonSegment: View {
    let phase: DayPhase
    let color: Color
    let width: CGFloat
    let isActive: Bool
    let progress: Double

    private var fillWidth: CGFloat {
        let rawWidth = width * progress
        if progress <= 0 { return 0 }
        return min(width, max(14, rawWidth))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.12)).frame(width: max(2, width), height: 14)
            RoundedRectangle(cornerRadius: 7).fill(color.opacity(isActive ? 1.0 : 0.4)).frame(width: fillWidth, height: 14)
            if isActive {
                RoundedRectangle(cornerRadius: 7).fill(color).frame(width: fillWidth, height: 14).shadow(color: color.opacity(0.8), radius: 5).blur(radius: 1)
            }
        }
        .frame(height: 18)
    }
}

struct TimelineRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isNow: Bool
    let infoKey: String
    @State private var showInfo = false
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    var body: some View {
        HStack(spacing: 16) {
            ZStack { 
                Circle().fill(color.opacity(0.1)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(color) 
            }
            
            VStack(alignment: .leading, spacing: 2) { 
                HStack(spacing: 8) {
                    Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    if isNow {
                        Text(AppTranslation.get("now_label", lang: appLanguage).uppercased())
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(color.opacity(0.15))
                            .foregroundColor(color)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: color.opacity(0.5), radius: 4)
                    }
                }
                Text(subtitle).font(.system(size: 13, design: .rounded)).foregroundColor(.secondary) 
            }
            Spacer()
            
            Button { showInfo.toggle() } label: { Image(systemName: "info.circle").foregroundColor(.primary.opacity(0.2)) }
            .popover(isPresented: $showInfo) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.primary)
                    Text(AppTranslation.get(infoKey, lang: appLanguage)).font(.system(size: 14)).lineSpacing(3).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .padding(20).frame(width: 280).presentationCompactAdaptation(.popover)
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 20)
    }
}
