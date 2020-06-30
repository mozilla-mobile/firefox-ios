/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WidgetKit
import SwiftUI

struct TodayStrings {
    static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", tableName: "Today", value: "Private Search", comment: "New Private Tab button label")
    static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabel", tableName: "Today", value: "New Search", comment: "New Tab button label")
    static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", tableName: "Today", value: "Go to copied link", comment: "Go to link on clipboard")
}

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

    var body: some View {
        VStack {
            Link(destination: url) {
                Image(imageName)
                    .padding(.top, 5.0)
                    .padding(.horizontal, 40)
                    .frame(minWidth: 60.0, minHeight: 60.0)

                if let label = label {
                    Text(label)
                        .foregroundColor(Color("widgetLabelColors"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 10.0)
                        .frame(minHeight: 12)
                        .font(.body)
                }
            }
        }
    }
}

struct NewTodayEntryView : View {
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        switch family {
        case .systemSmall:
            ZStack {
                Color("WidgetBackground")
                VStack {
                    HStack(alignment: .center, spacing: 15.0) {
                        ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false"))
                        ImageButtonWithLabel(imageName: "private-search", url: linkToContainingApp("?private=true"))
                    }
                    HStack(alignment: .center, spacing: 15.0) {
                        ImageButtonWithLabel(imageName: "close-private-tabs", url: linkToContainingApp("?private=true"))
                    }
                }
                .padding()
            }
        default:
            ZStack {
                Color("WidgetBackground")
                HStack(alignment: .top, spacing: 20.0) {
                    ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false"), label: TodayStrings.NewTabButtonLabel)
                    ImageButtonWithLabel(imageName: "private-search", url: linkToContainingApp("?private=true"), label: TodayStrings.NewPrivateTabButtonLabel)
                    ImageButtonWithLabel(imageName: "close-private-tabs", url: linkToContainingApp("?private=true"), label: "Close Private Tabs")
                }
                .padding()
            }
        }
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
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Search")
        .description("This is an example widget.")
    }

    private func clipboardChanged() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
