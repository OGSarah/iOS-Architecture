//
//  ForecastTimelineProvider.swift
//  AuroraWatch-MVVMWidget
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import WidgetKit

/// One point on the widget timeline: the Kp for a forecast window,
/// fully resolved into display strings.
///
/// The widget reuses the app's model layer (``ForecastService``,
/// ``StormLevel``, ``ForecastFormatting``) without a view model in
/// between, which is the payoff of keeping rules on the model.
nonisolated struct ForecastEntry: TimelineEntry {

    /// When this entry becomes current.
    let date: Date

    /// The Kp value ready for display, such as "Kp 5.67".
    let kpText: String

    /// The Kp value for the gauge, clamped to the 0 to 9 scale.
    let gaugeValue: Double

    /// The scale label for compact families, such as "G1" or "Quiet".
    let scaleText: String

    /// The severity line for the rectangular family.
    let stormText: String

    /// A placeholder entry shown while the first fetch is pending.
    static var placeholder: ForecastEntry {
        ForecastEntry(date: .now, kpText: "Kp --", gaugeValue: 0, scaleText: "--", stormText: "Loading")
    }

    /// Builds an entry from a forecast window.
    init(date: Date, window: ForecastWindow) {
        self.init(
            date: date,
            kpText: ForecastFormatting.kpString(window.kp),
            gaugeValue: min(max(window.kp, 0), 9),
            scaleText: window.stormLevel.scaleLabel ?? window.stormLevel.title,
            stormText: ForecastFormatting.stormDescriptor(for: window.stormLevel)
        )
    }

    private init(date: Date, kpText: String, gaugeValue: Double, scaleText: String, stormText: String) {
        self.date = date
        self.kpText = kpText
        self.gaugeValue = gaugeValue
        self.scaleText = scaleText
        self.stormText = stormText
    }
}

/// Drives the complication and Smart Stack widget from the same
/// ``ForecastService`` the app uses.
nonisolated struct ForecastTimelineProvider: TimelineProvider {

    /// The forecast source. Always the live service; the widget renders
    /// outside the app process, so no stub seam is needed here.
    private let service: any ForecastService = LiveForecastService()

    func placeholder(in context: Context) -> ForecastEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ForecastEntry) -> Void) {
        Task {
            completion(await currentEntry() ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ForecastEntry>) -> Void) {
        Task {
            let refreshDate = Date().addingTimeInterval(60 * 60)
            guard let entry = await currentEntry() else {
                completion(Timeline(entries: [.placeholder], policy: .after(refreshDate)))
                return
            }
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    /// Fetches the forecast and resolves the window that matters now:
    /// the one containing the current instant, else the next upcoming one,
    /// else the most recent.
    private func currentEntry() async -> ForecastEntry? {
        guard let windows = try? await service.windows(), !windows.isEmpty else {
            return nil
        }

        let now = Date()
        let windowLength: TimeInterval = 3 * 60 * 60
        let window = windows.first { $0.date <= now && now < $0.date.addingTimeInterval(windowLength) }
            ?? windows.first { $0.date > now }
            ?? windows[windows.count - 1]

        return ForecastEntry(date: now, window: window)
    }
}
