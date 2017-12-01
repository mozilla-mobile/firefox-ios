/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Telemetry

//
// 'Unified Telemetry' is the name for Mozilla's telemetry system
//
class UnifiedTelemetry {
    init(profile: Profile) {
        NotificationCenter.default.addObserver(self, selector: #selector(uploadError(notification:)), name: Telemetry.notificationReportError, object: nil)

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "Fennec"
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.dataDirectory = .documentDirectory
        telemetryConfig.updateChannel = AppConstants.BuildChannel.rawValue
        let sendUsageData = profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
        telemetryConfig.isCollectionEnabled = sendUsageData
        telemetryConfig.isUploadEnabled = sendUsageData

        let prefs = profile.prefs
        Telemetry.default.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String: Any?] in
            var outputDict = inputDict // make a mutable copy
            if let newTabChoice = prefs.stringForKey(NewTabAccessors.PrefKey) {
                outputDict["defaultNewTabExperience"] = newTabChoice as AnyObject?
            }
            if let chosenEmailClient = prefs.stringForKey(PrefsKeys.KeyMailToOption) {
                outputDict["defaultMailClient"] = chosenEmailClient as AnyObject?
            }
            return outputDict
        }

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: MobileEventPingBuilder.self)
    }

    @objc func uploadError(notification: NSNotification) {
        guard !DeviceInfo.isSimulator(), let error = notification.userInfo?["error"] as? NSError else { return }
        Sentry.shared.send(message: "Upload Error", tag: SentryTag.unifiedTelemetry, severity: .info, description: error.debugDescription)
    }
}

// Enums for Event telemetry.
extension UnifiedTelemetry {
    public enum EventCategory: String {
        case action = "action"
    }

    public enum EventMethod: String {
        case add = "add"
        case background = "background"
        case delete = "delete"
        case foreground = "foreground"
        case open = "open"
        case tap = "tap"
        case view = "view"
    }

    public enum EventObject: String {
        case app = "app"
        case bookmark = "bookmark"
        case bookmarksPanel = "bookmarks-panel"
        case readerModeCloseButton = "reader-mode-close-button"
        case readerModeOpenButton = "reader-mode-open-button"
        case readingListItem = "reading-list-item"
        case setting = "setting"
    }

    public enum EventValue: String {
        case appMenu = "app-menu"
        case awesomebarResults = "awesomebar-results"
        case bookmarksPanel = "bookmarks-panel"
        case homePanelHighlights = "home-panel-highlights"
        case homePanelPocketStories = "home-panel-pocket-stories"
        case homePanelTabButton = "home-panel-tab-button"
        case homePanelTopSites = "home-panel-top-sites"
        case longPress = "long-press"
        case markAsRead = "mark-as-read"
        case pageActionMenu = "page-action-menu"
        case readerModeToolbar = "reader-mode-toolbar"
        case shareExtension = "share-extension"
        case shareMenu = "share-menu"
        case swipe = "swipe"
    }

    public static func recordEvent(category: EventCategory, method: EventMethod, object: EventObject, value: EventValue? = nil, extras: [String : Any?]? = nil) {
        Telemetry.default.recordEvent(category: category.rawValue, method: method.rawValue, object: object.rawValue, value: value?.rawValue, extras: extras)
    }
}
