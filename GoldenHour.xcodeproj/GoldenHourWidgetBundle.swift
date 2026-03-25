import WidgetKit
import SwiftUI

@main
struct GoldenHourWidgetBundle: WidgetBundle {
    var body: some Widget {
        GoldenHourWidget()
        GoldenHourWidgetControl()
        // Asigură-te că aici scrie exact numele structurii din fișierul tău de design
        GoldenHourWidgetLiveActivity() 
    }
}
