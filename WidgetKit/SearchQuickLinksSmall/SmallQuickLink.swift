/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit

struct IntentProvider: IntentTimelineProvider {
    typealias Intent = QuickLinkSelectionIntent
    public typealias Entry = QuickActionEntry

    public func snapshot(for configuration: Intent, with context: Context, completion: @escaping (QuickActionEntry) -> ()) {
        let entry = QuickLinkEntry(date: Date(), link: QuickLink.from(configuration))
        completion(entry)
    }

    public func timeline(for configuration: Intent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let link = QuickLink.from(configuration)
        let entries = [QuickLinkEntry(date: Date(), link: link)]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct QuickLinkEntry: TimelineEntry {
    public let date: Date
    let link: QuickLink
}

struct SmallQuickLinkView : View {
    var entry: IntentProvider.Entry

    @ViewBuilder
    var body: some View {
        ImageButtonWithLabel(action: entry.link)
    }
}

struct SmallQuickLinkWidget: Widget {
    private let kind: String = "Quick Actions - Small"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: QuickActionSelectionIntent.self, provider: IntentProvider()) { entry in
            SmallQuickActionView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Firefox - Quick Actions")
        .description("Access to frequent actions directly on your home screen.")
    }
}

struct SmallQuickActionsPreviews: PreviewProvider {
    static let testEntry = QuickActionEntry(date: Date(), action: .search)
    static var previews: some View {
        Group {
            SmallQuickActionView(entry: testEntry)
                .environment(\.colorScheme, .dark)
        }
    }
}
