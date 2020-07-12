/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WidgetKit
import SwiftUI
import Shared

private struct TodayUX {
    static let linkTextSize: CGFloat = 9.0
    static let labelTextSize: CGFloat = 12.0
    static let imageButtonTextSize: CGFloat = 13.0
    static let copyLinkImageWidth: CGFloat = 20
    static let margin: CGFloat = 8
    static let buttonsHorizontalMarginPercentage: CGFloat = 0.1
}

struct Provider: TimelineProvider {
    public typealias Entry = SimpleEntry

    public func snapshot(with context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

var scheme: String {
    guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
        // Something went wrong/weird, but we should fallback to the public one.
        return "firefox"
    }
    return string
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
}

struct ImageButtonWithLabel: View {
    var imageName: String
    var url: URL
    var label: String? = ""
    var isPrivate: Bool = false

    var body: some View {
        Link(destination: url) {
            ZStack(alignment: .leading) {
                if isPrivate {
                    ContainerRelativeShape()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color("privateGradientOne"), Color("privateGradientTwo")]), startPoint: /*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/, endPoint: /*@START_MENU_TOKEN@*/.trailing/*@END_MENU_TOKEN@*/))
                } else {
                    ContainerRelativeShape()
                        .fill(Color("normalBackgroundColor"))
                }

                VStack(alignment: .leading) {
                    Image(imageName)
                        .scaledToFit()
                        .frame(height: 24.0)

                    if let label = label {
                        Text(label)
                            .foregroundColor(Color("widgetLabelColors"))
                    }
                }
                .padding(.leading, 10.0)
            }
        }
    }
}

struct NewTodayEntryView : View {
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 10.0) {
                ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false"), label: String.NewTabButtonLabel)
                ImageButtonWithLabel(imageName: "smallPrivateMask", url: linkToContainingApp("?private=true"), label: String.NewPrivateTabButtonLabel, isPrivate: true)
            }
            HStack(alignment: .top, spacing: 10.0) {
                ImageButtonWithLabel(imageName: "copy_link_icon", url: linkToContainingApp("?clipboard"), label: String.GoToCopiedLinkLabel)
                ImageButtonWithLabel(imageName: "delete", url: linkToContainingApp("?private=true"), label: "Close Private Tabs", isPrivate: true)
            }
        }
        .padding(10.0)
        .background(Color("WidgetBackground"))
    }

    fileprivate func linkToContainingApp(_ urlSuffix: String = "") -> URL {
        let urlString = "\(scheme)://open-url\(urlSuffix)"
        return URL(string: urlString)!
    }
}

@main
struct NewToday: Widget {
    private let kind: String = "Search"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(), placeholder: NewTodayEntryView()) { entry in
            NewTodayEntryView()
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Search")
        .description("This is an example widget.")
    }

    private func clipboardChanged() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
