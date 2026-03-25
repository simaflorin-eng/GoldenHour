import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct GoldenHourAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phaseName: String
        var phaseIcon: String
        var phaseColor: String
        var endTime: Date
        var progress: Double
    }
    
    var activityName: String = "Golden Hour"
}
#endif

