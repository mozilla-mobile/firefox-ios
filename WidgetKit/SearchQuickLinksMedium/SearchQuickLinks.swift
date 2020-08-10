/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WidgetKit
import SwiftUI
import Shared

struct Provider: TimelineProvider {
    public typealias Entry = SimpleEntry

    public func snapshot(with context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

var scheme: String {
    guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
        return "firefox"
    }
    return string
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
}

struct SearchActionsUX {
    static let searchButtonColors = [Color("searchButtonColorTwo"), Color("searchButtonColorOne")]
    static let privateTabsColors = [Color("privateGradientThree"), Color("privateGradientTwo"),Color("privateGradientOne")]
    static let goToCopiedLinkColors = [Color("goToCopiedLinkColorTwo"), Color("goToCopiedLinkColorOne")]
}

struct SearchQuickLinksEntryView : View {
    @Environment(\.widgetFamily) var family
    static var copiedURL: URL?
    static var searchedText : String?

    @ViewBuilder
    var body: some View {
        
        VStack {
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "faviconFox", url: linkToContainingApp("?private=false", query: "open-url"), label: "Search in Firefox", ButtonGradient: Gradient(colors: SearchActionsUX.searchButtonColors))
                ImageButtonWithLabel(imageName: "smallPrivateMask", url: linkToContainingApp("?private=true", query: "open-url"), label: String.NewPrivateTabButtonLabel,ButtonGradient: Gradient(colors: SearchActionsUX.privateTabsColors))
            }
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "copy_link_icon", url: linkToContainingApp(query: "open-copied"), label: String.GoToCopiedLinkLabelV2, ButtonGradient: Gradient(colors: SearchActionsUX.goToCopiedLinkColors))
                ImageButtonWithLabel(imageName: "delete", url: linkToContainingApp(query: "close-private-tabs"), label: String.closePrivateTabsButtonLabel, ButtonGradient: Gradient(colors: SearchActionsUX.privateTabsColors))
            }
        }

        .padding(10.0)
        .background(Color("backgroundColor"))
    }
   

    fileprivate func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}

struct SearchQuickLinksWigdet: Widget {
    private let kind: String = "Quick Actions - Medium"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(), placeholder: SearchQuickLinksEntryView()) { entry in
            SearchQuickLinksEntryView()
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Firefox - Quick Actions")
        .description("This is an example widget.")
    }
}

struct SearchQuickLinksPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchQuickLinksEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            SearchQuickLinksEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.colorScheme, .dark)

            SearchQuickLinksEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.sizeCategory, .small)

            SearchQuickLinksEntryView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.sizeCategory, .accessibilityLarge)
        }
    }
}
