import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let phaseName: String
    let phaseIcon: String
    let phaseColor: String
    let progress: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), phaseName: "Loading...", phaseIcon: "sun.max.fill", phaseColor: "#FF9500", progress: 0.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), phaseName: "Peak Focus", phaseIcon: "brain.head.profile", phaseColor: "#FF9500", progress: 0.7))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = SimpleEntry(date: Date(), phaseName: "Peak Focus", phaseIcon: "brain.head.profile", phaseColor: "#FF9500", progress: 0.7)
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct Golden_Hour_WidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.phaseIcon).foregroundColor(Color(hexRGB: entry.phaseColor, fallback: .orange))
                Text(entry.phaseName).font(.headline)
            }
            ProgressView(value: entry.progress).tint(Color(hexRGB: entry.phaseColor, fallback: .orange))
            Spacer()
            Text("Golden Hour").font(.caption2).foregroundColor(.secondary)
        }
    }
}

// ASIGURĂ-TE CĂ NU EXISTĂ @main AICI!
struct Golden_Hour_Widget: Widget {
    let kind: String = "Golden_Hour_Widget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Golden_Hour_WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Golden Hour Status")
        .description("Vezi faza curentă.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

