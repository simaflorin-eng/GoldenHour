import WidgetKit
import SwiftUI

enum WidgetDayPhase: String {
    case morningPrep = "morning_prep"
    case focus = "focus"
    case caffeine = "caffeine"
    case afternoon = "afternoon"
    case sunset = "sunset"
    case idle = "idle"

    var icon: String {
        switch self {
        case .morningPrep: return "sunrise.fill"
        case .focus: return "brain.head.profile"
        case .caffeine: return "cup.and.saucer.fill"
        case .afternoon: return "sun.max.trianglebadge.exclamationmark"
        case .sunset: return "sunset.fill"
        case .idle: return "moon.stars.fill"
        }
    }

    var hexColor: String {
        switch self {
        case .morningPrep: return "#00FFFF"
        case .focus: return "#FF9500"
        case .caffeine: return "#A2845E"
        case .afternoon: return "#2FBF71"
        case .sunset: return "#5856D6"
        case .idle: return "#AF52DE"
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let wakeUpTime: Date
    let sunsetTime: Date
    let phase: WidgetDayPhase
    let phaseEndTime: Date
    let progress: Double
}

struct Provider: TimelineProvider {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.florinsima.GoldenHour")

    func placeholder(in context: Context) -> SimpleEntry {
        let now = Date()
        return SimpleEntry(
            date: now,
            wakeUpTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now,
            sunsetTime: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: now) ?? now,
            phase: .focus,
            phaseEndTime: now.addingTimeInterval(3600),
            progress: 0.5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let now = Date()
        let entry = makeEntry(for: now)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry(for date: Date) -> SimpleEntry {
        let wakeTimestamp = sharedDefaults?.double(forKey: "wakeUpTime") ?? 0
        let sunsetTimestamp = sharedDefaults?.double(forKey: "sunsetTime") ?? 0
        let endTimestamp = sharedDefaults?.double(forKey: "currentPhaseEnd") ?? 0
        let progress = sharedDefaults?.double(forKey: "currentPhaseProgress") ?? 0
        let phaseRaw = sharedDefaults?.string(forKey: "currentPhase") ?? WidgetDayPhase.morningPrep.rawValue

        let wake = wakeTimestamp > 0 ? Date(timeIntervalSince1970: wakeTimestamp) : Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: date) ?? date
        let sunset = sunsetTimestamp > 0 ? Date(timeIntervalSince1970: sunsetTimestamp) : Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: date) ?? date
        let phaseEnd = endTimestamp > 0 ? Date(timeIntervalSince1970: endTimestamp) : date.addingTimeInterval(3600)
        let phase = WidgetDayPhase(rawValue: phaseRaw) ?? .morningPrep

        return SimpleEntry(
            date: date,
            wakeUpTime: wake,
            sunsetTime: sunset,
            phase: phase,
            phaseEndTime: phaseEnd,
            progress: progress
        )
    }
}

struct Golden_Hour_WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallGaugeWidget(entry: entry)
        default:
            MediumRailWidget(entry: entry)
        }
    }
}

struct Golden_Hour_Widget: Widget {
    let kind: String = "Golden_Hour_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Golden_Hour_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Golden Hour Status")
        .description("See the current circadian phase.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct SmallGaugeWidget: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.phase.icon)
                    .foregroundStyle(activeColor)
                Spacer()
                Text(entry.phaseEndTime, style: .timer)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                let lineWidth: CGFloat = 14
                let radius = (min(geo.size.width, geo.size.height + 40) - lineWidth) / 2
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
                let angle = Angle(degrees: -180 + (180 * progressPosition))

                ZStack {
                    WidgetGaugeArc(startAngle: .degrees(-180), endAngle: .degrees(0))
                        .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                    ForEach(gaugeSegments) { segment in
                        WidgetGaugeArc(startAngle: segment.startAngle, endAngle: segment.endAngle)
                            .stroke(segment.phase == entry.phase ? activeColor : Color.primary.opacity(0.18), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }

                    Path { path in
                        path.move(to: center)
                        path.addLine(to: widgetPoint(on: radius - 16, angle: angle, center: center))
                    }
                    .stroke(activeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                    Circle()
                        .fill(activeColor)
                        .frame(width: 10, height: 10)
                        .position(center)
                }
            }
            .frame(height: 70)

            Text(entry.phase.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private var activeColor: Color {
        Color(hexRGB: entry.phase.hexColor, fallback: .orange)
    }

    private var widgetPhases: [(phase: WidgetDayPhase, start: Date, end: Date)] {
        let wake = entry.wakeUpTime
        let morningEnd = wake.addingTimeInterval(2 * 3600)
        let focusEnd = morningEnd.addingTimeInterval(90 * 60)
        let caffeineEnd = wake.addingTimeInterval(8 * 3600)
        let sunsetStart = max(caffeineEnd, entry.sunsetTime.addingTimeInterval(-30 * 60))
        return [
            (.morningPrep, wake, morningEnd),
            (.focus, morningEnd, focusEnd),
            (.caffeine, focusEnd, caffeineEnd),
            (.afternoon, caffeineEnd, sunsetStart),
            (.sunset, sunsetStart, entry.sunsetTime)
        ]
    }

    private var progressPosition: Double {
        let phases = widgetPhases
        guard let current = phases.first(where: { $0.phase == entry.phase }),
              let overallStart = phases.first?.start,
              let overallEnd = phases.last?.end
        else { return 0 }

        let elapsedBeforeCurrent = current.start.timeIntervalSince(overallStart)
        let elapsedInCurrent = current.end.timeIntervalSince(current.start) * entry.progress
        let total = max(1, overallEnd.timeIntervalSince(overallStart))
        return max(0, min(1, (elapsedBeforeCurrent + elapsedInCurrent) / total))
    }

    private var gaugeSegments: [WidgetGaugeSegment] {
        let phases = widgetPhases
        guard let start = phases.first?.start, let end = phases.last?.end else { return [] }
        let total = max(1, end.timeIntervalSince(start))

        return phases.map { item in
            let startRatio = item.start.timeIntervalSince(start) / total
            let endRatio = item.end.timeIntervalSince(start) / total
            return WidgetGaugeSegment(
                phase: item.phase,
                startAngle: .degrees(-180 + (180 * startRatio)),
                endAngle: .degrees(-180 + (180 * endRatio))
            )
        }
    }
}

private struct MediumRailWidget: View {
    let entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.phase.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                    Text(entry.phaseEndTime, style: .timer)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                }
                Spacer()
                Image(systemName: entry.phase.icon)
                    .foregroundStyle(activeColor)
            }

            GeometryReader { geo in
                let metrics = railMetrics(width: geo.size.width)
                ZStack {
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.07))
                        .frame(height: 6)
                        .position(x: geo.size.width / 2, y: metrics.baselineY)

                    ForEach(metrics.segments) { segment in
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(segment.phase == entry.phase ? activeColor : Color.primary.opacity(0.16))
                            .frame(width: segment.width, height: segment.height)
                            .position(x: segment.midX, y: metrics.baselineY)
                    }

                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(activeColor)
                        .frame(width: 8, height: metrics.activeHeight + 16)
                        .position(x: metrics.markerX, y: metrics.baselineY)
                }
            }
            .frame(height: 56)

            HStack {
                Text(entry.wakeUpTime.formatted(date: .omitted, time: .shortened))
                Spacer()
                Text(entry.sunsetTime.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(14)
    }

    private var activeColor: Color {
        Color(hexRGB: entry.phase.hexColor, fallback: .orange)
    }

    private var widgetPhases: [(phase: WidgetDayPhase, start: Date, end: Date)] {
        let wake = entry.wakeUpTime
        let morningEnd = wake.addingTimeInterval(2 * 3600)
        let focusEnd = morningEnd.addingTimeInterval(90 * 60)
        let caffeineEnd = wake.addingTimeInterval(8 * 3600)
        let sunsetStart = max(caffeineEnd, entry.sunsetTime.addingTimeInterval(-30 * 60))
        return [
            (.morningPrep, wake, morningEnd),
            (.focus, morningEnd, focusEnd),
            (.caffeine, focusEnd, caffeineEnd),
            (.afternoon, caffeineEnd, sunsetStart),
            (.sunset, sunsetStart, entry.sunsetTime)
        ]
    }

    private func railMetrics(width: CGFloat) -> (segments: [WidgetRailSegment], markerX: CGFloat, baselineY: CGFloat, activeHeight: CGFloat) {
        let phases = widgetPhases
        guard let start = phases.first?.start, let end = phases.last?.end else { return ([], 0, 28, 20) }

        let total = max(1, end.timeIntervalSince(start))
        let inset: CGFloat = 4
        let contentWidth = max(1, width - inset * 2)
        let baselineY: CGFloat = 28
        let heights: [WidgetDayPhase: CGFloat] = [.morningPrep: 18, .focus: 28, .caffeine: 20, .afternoon: 14, .sunset: 12, .idle: 10]

        let segments = phases.map { item in
            let startRatio = CGFloat(item.start.timeIntervalSince(start) / total)
            let endRatio = CGFloat(item.end.timeIntervalSince(start) / total)
            let startX = inset + (contentWidth * startRatio)
            let endX = inset + (contentWidth * endRatio)
            return WidgetRailSegment(
                phase: item.phase,
                startX: startX,
                endX: endX,
                midX: (startX + endX) / 2,
                width: max(8, endX - startX),
                height: heights[item.phase] ?? 14
            )
        }

        let markerOffset = phases.reduce(0.0) { partial, item in
            if item.phase == entry.phase {
                return partial + (item.end.timeIntervalSince(item.start) * entry.progress)
            }

            if item.end <= (phases.first(where: { $0.phase == entry.phase })?.start ?? entry.date) {
                return partial + item.end.timeIntervalSince(item.start)
            }

            return partial
        }

        let markerX = inset + (contentWidth * CGFloat(max(0, min(1, markerOffset / total))))
        let activeHeight = segments.first(where: { $0.phase == entry.phase })?.height ?? 20
        return (segments, markerX, baselineY, activeHeight)
    }
}

private struct WidgetGaugeSegment: Identifiable {
    let id = UUID()
    let phase: WidgetDayPhase
    let startAngle: Angle
    let endAngle: Angle
}

private struct WidgetRailSegment: Identifiable {
    let id = UUID()
    let phase: WidgetDayPhase
    let startX: CGFloat
    let endX: CGFloat
    let midX: CGFloat
    let width: CGFloat
    let height: CGFloat
}

private struct WidgetGaugeArc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

private func widgetPoint(on radius: CGFloat, angle: Angle, center: CGPoint) -> CGPoint {
    CGPoint(
        x: center.x + (cos(CGFloat(angle.radians)) * radius),
        y: center.y + (sin(CGFloat(angle.radians)) * radius)
    )
}
