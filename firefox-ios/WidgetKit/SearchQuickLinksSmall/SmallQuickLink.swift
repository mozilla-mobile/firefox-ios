// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct IntentProvider: IntentTimelineProvider {
    typealias Intent = QuickActionIntent
    typealias Entry = QuickLinkEntry

    func getSnapshot(
        for configuration: QuickActionIntent,
        in context: Context,
        completion: @escaping (QuickLinkEntry) -> Void
    ) {
        let entry = QuickLinkEntry(date: Date(), link: .search)
        completion(entry)
    }

    func getTimeline(
        for configuration: QuickActionIntent,
        in context: Context,
        completion: @escaping (Timeline<QuickLinkEntry>) -> Void
    ) {
        let entry = QuickLinkEntry(date: Date(), link: QuickLink(rawValue: configuration.actionType.rawValue)!)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    func placeholder(in context: Context) -> QuickLinkEntry {
        return QuickLinkEntry(date: Date(), link: .search)
    }
}

struct QuickLinkEntry: TimelineEntry {
    public let date: Date
    let link: QuickLink
}

struct SmallQuickLinkView: View {
    var entry: IntentProvider.Entry

    @ViewBuilder var body: some View {
        ImageButtonWithLabel(isSmall: true, link: entry.link)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground(
                LinearGradient(
                    gradient: Gradient(colors: entry.link.backgroundColors),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .widgetURL(entry.link.smallWidgetUrl)
    }
}

struct SmallQuickLinkWidget: Widget {
    private let kind: String = "Quick Actions - Small"

    public var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: QuickActionIntent.self, provider: IntentProvider()) { entry in
            SmallQuickLinkView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName(String.QuickActionsGalleryTitle)
        .description(String.QuickActionGalleryDescription)
        .contentMarginsDisabled()
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
#endif
