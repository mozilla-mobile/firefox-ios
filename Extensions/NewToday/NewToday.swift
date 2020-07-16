/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WidgetKit
import SwiftUI
import Shared
import NotificationCenter


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
                        .fill(LinearGradient(gradient: Gradient(colors: [Color("privateGradientOne"), Color("privateGradientTwo")]), startPoint: .leading, endPoint: .trailing))
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
                            .font(.headline)
                            .foregroundColor(Color("widgetLabelColors"))
                    }
                }
                .padding(.leading, 8.0)
            }
        }
    }
}

struct NewTodayEntryView : View {
    @Environment(\.widgetFamily) var family


    static var copiedURL: URL?
    static var searchedText : String?
    
    @ViewBuilder
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false", query: "url"), label: "New Search")
                ImageButtonWithLabel(imageName: "smallPrivateMask", url: linkToContainingApp("?private=true", query: "url"), label: "Private Search", isPrivate: true)
            }
            HStack(alignment: .top, spacing: 8.0) {
                ImageButtonWithLabel(imageName: "copy_link_icon", url: onPressOpenClibpoard(), label: "Go To Copied Link")
                ImageButtonWithLabel(imageName: "delete", url: linkToContainingApp("?private=true", query: "close-private-tabs"), label: "Close Private Tabs", isPrivate: true)
            }
        }
        .padding(10.0)
        .background(Color("WidgetBackground"))
    }

    fileprivate func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://open-\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
    
    func updateCopiedLink() {
        if !UIPasteboard.general.hasURLs {
            guard let searchText = UIPasteboard.general.string else {
                NewTodayEntryView.searchedText = nil
                return
            }
            NewTodayEntryView.searchedText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        else {
            UIPasteboard.general.asyncURL().uponQueue(.main) { res in
                guard let url: URL? = res.successValue else {
                    NewTodayEntryView.copiedURL = nil
                    return
                }
                NewTodayEntryView.copiedURL = url
            }
            
        }
    }
    
    func onPressOpenClibpoard() -> URL {
        updateCopiedLink()
        if let url = NewTodayEntryView.copiedURL,
            let encodedString = url.absoluteString.escape() {
            return linkToContainingApp("?url=\(encodedString)",query: "url")
        } else {
            if let copiedText = NewTodayEntryView.searchedText {
                return linkToContainingApp("?text=\(copiedText)",query: "text")
            }
        }
        return linkToContainingApp("?private=false",query: "url")
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
}
