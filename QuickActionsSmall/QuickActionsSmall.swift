//
//  QuickActionsSmall.swift
//  QuickActionsSmall
//
//  Created by McNoor's  on 8/8/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import WidgetKit
import SwiftUI

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

struct QuickActionsSmallEntryView : View {
    var body: some View {
        ImageButtonWithLabel(imageName: "copy_link_icon", url: linkToContainingApp(query: "open-copied"), label: "Go To Copied Link", ButtonGradient: Gradient(colors: SearchActionsUX.goToCopiedLinkColors))
    }
    fileprivate func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
         let urlString = "\(scheme)://\(query)\(urlSuffix)"
         return URL(string: urlString)!
     }
}

@main
struct QuickActionsSmall: Widget {
    private let kind: String = "QuickActionsSmall"

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(), placeholder: QuickActionsSmallEntryView()) { entry in
            QuickActionsSmallEntryView()
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickActionsSmall_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionsSmallEntryView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
