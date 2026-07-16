//
//  AuroraWatchWidget.swift
//  AuroraWatch-MVVMWidget
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI
import WidgetKit

/// The widget bundle entry point for the complication target.
@main
struct AuroraWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        AuroraWatchWidget()
    }
}

/// The current Kp complication, in every accessory family.
///
/// `accessoryRectangular` is what the Smart Stack shows; the other
/// families cover watch face slots.
struct AuroraWatchWidget: Widget {

    /// The widget kind identifier WidgetKit tracks this widget by.
    let kind = "AuroraWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ForecastTimelineProvider()) { entry in
            AuroraWatchWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Current Kp")
        .description("The current planetary K-index and the storm level it maps to.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular])
    }
}

/// Renders a ``ForecastEntry`` for whichever family the slot demands.
///
/// Like every other view in the project, it is a pure function of the
/// finished strings it is handed; the timeline provider resolved them
/// through the shared model layer.
struct AuroraWatchWidgetView: View {

    /// The accessory family of the slot this instance renders into.
    @Environment(\.widgetFamily) private var family

    /// The resolved timeline entry to display.
    let entry: ForecastEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.kpText) \(entry.scaleText)")

        case .accessoryCorner:
            Text(entry.scaleText)
                .font(.headline)
                .widgetLabel {
                    Gauge(value: entry.gaugeValue, in: 0 ... 9) {
                        Text("Kp")
                    }
                }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.kpText)
                    .font(.headline)
                Text(entry.stormText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            gauge
        }
    }

    /// The circular gauge shared by the circular family and the fallback.
    private var gauge: some View {
        Gauge(value: entry.gaugeValue, in: 0 ... 9) {
            Text("Kp")
        } currentValueLabel: {
            Text(entry.gaugeValue.formatted(.number.precision(.fractionLength(0 ... 1))))
        }
        .gaugeStyle(.accessoryCircular)
    }
}

#Preview("Rectangular", as: .accessoryRectangular) {
    AuroraWatchWidget()
} timeline: {
    ForecastEntry(date: .now, window: ForecastWindow(date: .now, kp: 5.67, observation: .estimated))
}

#Preview("Circular", as: .accessoryCircular) {
    AuroraWatchWidget()
} timeline: {
    ForecastEntry(date: .now, window: ForecastWindow(date: .now, kp: 5.67, observation: .estimated))
}
