// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .atEnd)
        completion(timeline)
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct FocusWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        SearchWidgetView()
    }
}

@main
struct FocusWidgets: Widget {
    let kind: String = "FocusWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName(UIConstants.strings.quickActionsGalleryTitle)
        .description(UIConstants.strings.quickActionGalleryDescription)
        .supportedFamilies([.systemSmall])
    }
}

struct FocusWidgets_Previews: PreviewProvider {
    static var previews: some View {
        FocusWidgetsEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
