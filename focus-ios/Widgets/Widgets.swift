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

struct FocusWidgetsEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        SearchWidgetView(title: String(format: .searchInAppFormat, String.appNameForBundle), padding: !Bool.isIOS17OrLater, background: false)
            .widgetURL(.deepLinkURL)
            .widgetBackground(backgroundView:
                                LinearGradient(
                                    gradient: .quickAccessWidget,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
    }
}

@main
struct Widgets: Widget {
    let kind = "Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FocusWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName(String.quickActionsGalleryTitle)
        .description(String(format: .quickActionGalleryDescriptionV2, String.appNameForBundle))
        .supportedFamilies([.systemSmall])
    }
}

struct FocusWidgets_Previews: PreviewProvider {
    static var previews: some View {
        FocusWidgetsEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

fileprivate extension String {
    static var appNameForBundle: String {
        var isKlar: Bool { return (Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String).contains("Klar") }
        return isKlar ? "Klar" : "Focus"
    }
    // Quick Action - Small Size - Gallery View
    static let quickActionGalleryDescriptionV2 = NSLocalizedString(
        "TodayWidget.QuickActionGalleryDescriptionV2",
        value: "Start a private search in %@ with your default search engine.",
        comment: "Description for small size widget to add it to home screen. %@ is the name of the app(Focus/Klar).")

    static let quickActionGalleryDescription = NSLocalizedString(
        "TodayWidget.QuickActionGalleryDescription",
        value: "Add a %@ shortcut to your Home screen. After adding the widget, touch and hold to edit it and select a different shortcut.",
        comment: "Description for small size widget to add it to home screen. %@ is the name of the app(Focus/Klar).")

    static let quickActionsGalleryTitle = NSLocalizedString(
        "TodayWidget.QuickActionsGalleryTitle",
        value: "Quick Actions",
        comment: "Quick Actions title when widget enters edit mode")

    static let searchInAppFormat = NSLocalizedString(
        "TodayWidget.SearchInApp",
        value: "Search in %@",
        comment: "Text shown on quick action widget inviting the user to browse in the app. %@ is the name of the app (Focus/Klar).")
    static let searchInApp = String(format: searchInAppFormat, AppInfo.shortProductName)
}

fileprivate extension Bool {
    static var isIOS17OrLater: Bool {
        if #available(iOS 17, *) {
            return true
        } else {
            return false
        }
    }
}

fileprivate extension URL {
    static let deepLinkURL = URL(string: "firefox-focus://widget")!
}

fileprivate extension View {
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(watchOS 10.0, iOSApplicationExtension 17.0, iOS 17.0, macOSApplicationExtension 14.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}
