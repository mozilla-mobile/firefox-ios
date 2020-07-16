//
//  TodayWidgetKit.swift
//  TodayWidgetKit
//
//  Created by McNoor's  on 7/16/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

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
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    public let date: Date
}

struct PlaceholderView : View {
    var body: some View {
        Text("Placeholder View")
    }
}

var scheme: String {
    guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
        // Something went wrong/weird, but we should fallback to the public one.
        return "firefox"
    }
    return string
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

struct TodayWidgetKitEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    @ViewBuilder
    var body: some View {
        VStack {
                    HStack(alignment: .top, spacing: 8.0) {
                        ImageButtonWithLabel(imageName: "search-button", url: linkToContainingApp("?private=false"), label: "New Search")
                        ImageButtonWithLabel(imageName: "smallPrivateMask", url: linkToContainingApp("?private=true"), label: "Private Search", isPrivate: true)
                    }
                    HStack(alignment: .top, spacing: 8.0) {
                        ImageButtonWithLabel(imageName: "copy_link_icon", url: linkToContainingApp("?clipboard"), label: "Go To Copied Link")
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
struct TodayWidgetKit: Widget {
    private let kind: String = "TodayWidgetKit"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(), placeholder: PlaceholderView()) { entry in
            TodayWidgetKitEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct TodayWidgetKit_Previews: PreviewProvider {
    static var previews: some View {
        TodayWidgetKitEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
