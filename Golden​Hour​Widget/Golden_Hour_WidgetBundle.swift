import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct Golden_Hour_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Golden_Hour_Widget()
        
        #if canImport(ActivityKit)
        GoldenHourLiveActivity()
        #endif
        
        controlWidgets
    }
    
    @WidgetBundleBuilder
    var controlWidgets: some Widget {
        if #available(iOS 18.0, watchOS 11.0, macOS 15.0, visionOS 2.0, *) {
            Golden_Hour_WidgetControl()
        }
    }
}
