import ActivityKit
import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
struct GoldenHourLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoldenHourAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.phaseName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.secondary)
                        Text(context.state.endTime, style: .timer)
                            .font(.system(.title3, design: .monospaced, weight: .bold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    MiniIslandGauge(
                        color: activeColor(for: context),
                        progress: context.state.progress
                    )
                    .frame(width: 34, height: 34)
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityRail(
                        phaseIcon: context.state.phaseIcon,
                        color: activeColor(for: context),
                        progress: context.state.progress
                    )
                    .frame(height: 40)
                }
            } compactLeading: {
                Image(systemName: context.state.phaseIcon)
                    .foregroundStyle(activeColor(for: context))
            } compactTrailing: {
                MiniIslandGauge(
                    color: activeColor(for: context),
                    progress: context.state.progress
                )
                .frame(width: 18, height: 18)
            } minimal: {
                Image(systemName: context.state.phaseIcon)
                    .foregroundStyle(activeColor(for: context))
            }
            .keylineTint(activeColor(for: context))
        }
    }

    private func activeColor(for context: ActivityViewContext<GoldenHourAttributes>) -> Color {
        Color(hexRGB: context.state.phaseColor, fallback: .orange)
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<GoldenHourAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.phaseName.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Image(systemName: context.state.phaseIcon)
                            .foregroundStyle(activeColor)
                        Text(context.state.endTime, style: .timer)
                            .font(.system(.title2, design: .monospaced, weight: .bold))
                    }
                }
                Spacer()
            }

            LiveActivityRail(
                phaseIcon: context.state.phaseIcon,
                color: activeColor,
                progress: context.state.progress
            )
            .frame(height: 44)
        }
    }

    private var activeColor: Color {
        Color(hexRGB: context.state.phaseColor, fallback: .orange)
    }
}

private struct LiveActivityRail: View {
    let phaseIcon: String
    let color: Color
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let baselineY = geo.size.height / 2 + 4
            let segmentWidths = normalizedWidths(total: geo.size.width)
            let heights: [CGFloat] = [18, 30, 22, 16, 12]
            let markerX = max(8, min(geo.size.width - 8, geo.size.width * progress))

            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                    .position(x: geo.size.width / 2, y: baselineY)

                HStack(spacing: 6) {
                    ForEach(Array(segmentWidths.enumerated()), id: \.offset) { index, width in
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(index == activeSegmentIndex ? color : Color.white.opacity(0.18))
                            .frame(width: width, height: heights[index])
                    }
                }
                .frame(maxWidth: .infinity)
                .position(x: geo.size.width / 2, y: baselineY)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color)
                    .frame(width: 8, height: heights[activeSegmentIndex] + 14)
                    .position(x: markerX, y: baselineY)
            }
        }
    }

    private var activeSegmentIndex: Int {
        switch progress {
        case ..<0.22: return 0
        case ..<0.42: return 1
        case ..<0.66: return 2
        case ..<0.88: return 3
        default: return 4
        }
    }

    private func normalizedWidths(total: CGFloat) -> [CGFloat] {
        let spacing: CGFloat = 6
        let values: [CGFloat] = [0.22, 0.2, 0.24, 0.22, 0.12]
        let available = total - (spacing * 4)
        return values.map { max(18, available * $0) }
    }
}

private struct MiniIslandGauge: View {
    let color: Color
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(0.02, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
#endif
