import ActivityKit
import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
struct GoldenHourLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoldenHourAttributes.self) { context in
            // LOCK SCREEN UI
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label {
                        Text(context.state.phaseName).font(.headline)
                    } icon: {
                        Image(systemName: context.state.phaseIcon).foregroundColor(Color(hexRGB: context.state.phaseColor, fallback: .orange))
                    }
                    Spacer()
                    Text(context.state.endTime, style: .timer).font(.system(.title3, design: .monospaced, weight: .bold)).foregroundColor(.secondary)
                }
                ProgressView(value: context.state.progress).tint(Color(hexRGB: context.state.phaseColor, fallback: .orange))
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.phaseIcon).font(.title2).foregroundColor(Color(hexRGB: context.state.phaseColor, fallback: .orange)).padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 4)
                        Circle().trim(from: 0, to: 1.0 - context.state.progress)
                            .stroke(Color(hexRGB: context.state.phaseColor, fallback: .orange), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.phaseName).font(.subheadline.bold()).foregroundColor(.secondary)
                        ProgressView(value: context.state.progress).tint(Color(hexRGB: context.state.phaseColor, fallback: .orange)).padding(.horizontal, 10)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phaseIcon)
                    .foregroundColor(Color(hexRGB: context.state.phaseColor, fallback: .orange))
                    .padding(.leading, 8)
                    .padding(.trailing, 12) // Îl împinge în stânga, departe de cameră
            } compactTrailing: {
                // Doar cercul, cu padding la stânga pentru a evita camera
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2.2)
                    Circle()
                        .trim(from: 0, to: 1.0 - context.state.progress)
                        .stroke(Color(hexRGB: context.state.phaseColor, fallback: .orange), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 18, height: 18)
                .padding(.leading, 12) // Îl împinge în dreapta, departe de cameră
                .padding(.trailing, 8)
            } minimal: {
                Image(systemName: context.state.phaseIcon).foregroundColor(Color(hexRGB: context.state.phaseColor, fallback: .orange))
            }
            .keylineTint(Color(hexRGB: context.state.phaseColor, fallback: .orange))
        }
    }
}

struct GoldenHourDetailedLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoldenHourAttributes.self) { context in
            Text(context.state.phaseName).padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("") }
            } compactLeading: { Text("") } compactTrailing: { Text("") } minimal: { Text("") }
        }
    }
}
#endif

