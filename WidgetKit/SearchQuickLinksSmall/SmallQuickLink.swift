/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit

struct IntentProvider: IntentTimelineProvider {
    typealias Intent = QuickLinkSelectionIntent
    public typealias Entry = QuickLinkEntry

    public func snapshot(for configuration: Intent, with context: Context, completion: @escaping (QuickLinkEntry) -> ()) {
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
        ImageButtonWithLabel(isSmall: true, link: entry.link)
    }
}

struct SmallQuickLinkWidget: Widget {
    private let kind: String = "Quick Actions - Small"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: QuickLinkSelectionIntent.self, provider: IntentProvider(), placeholder: SmallQuickLinkView(entry: QuickLinkEntry(date: Date(), link: .search))) { entry in
            SmallQuickLinkView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName(String.QuickActionsGalleryTitle)
        .description(String.QuickActionGalleryDescription)
    }
}

struct SmallQuickActionsPreviews: PreviewProvider {
    static let testEntry = QuickLinkEntry(date: Date(), link: .search)
    static var previews: some View {
        Group {
            SmallQuickLinkView(entry: testEntry)
                .environment(\.colorScheme, .dark)
        }
    }
}
