/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Telemetry

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let background = "background"
    public static let foreground = "foreground"
//    public static let typeURL = "type_url"
//    public static let typeQuery = "type_query"
//    public static let click = "click"
//    public static let change = "change"
//    public static let open = "open"
//    public static let openAppStore = "open_app_store"
//    public static let share = "share"
//    public static let swipeToNavigateBack = "swipe_to_navigate_back"
//    public static let swipeToNavigateForward = "swipe_to_navigate_forward"
}

class TelemetryEventObject {
    public static let app = "app"
//    public static let searchBar = "search_bar"
//    public static let eraseButton = "erase_button"
//    public static let settingsButton = "settings_button"
//    public static let setting = "setting"
//    public static let menu = "menu"
//    public static let pasteAndGo = "paste_and_go"
}

class UnifiedTelemetry {

    init(profile: Profile) {
        NotificationCenter.default.addObserver(self, selector: #selector(UnifiedTelemetry.appWillResignActive(notification:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(UnifiedTelemetry.appDidEnterBackground(notification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(UnifiedTelemetry.appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        setupCorePing(withProfile: profile)
    }

    @objc func appWillResignActive(notification: NSNotification) {
        Telemetry.default.recordSessionEnd()
    }

    @objc func appDidEnterBackground(notification: NSNotification) {
        Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)
    }

    @objc func appDidBecomeActive(notification: NSNotification) {
        Telemetry.default.recordSessionStart()
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
    }

    fileprivate func setupCorePing(withProfile profile: Profile) {
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = AppInfo.displayName
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.dataDirectory = .documentDirectory

        #if DEBUG
            telemetryConfig.updateChannel = "debug"
            telemetryConfig.isCollectionEnabled = false
            telemetryConfig.isUploadEnabled = false
        #else
            telemetryConfig.updateChannel = "release"
            let sendUsageData = profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
            telemetryConfig.isCollectionEnabled = sendUsageData
            telemetryConfig.isUploadEnabled = sendUsageData
        #endif


        // TODO: Add these items at ping root
//        if let newTabChoice = profile.prefs.stringForKey(NewTabAccessors.PrefKey) {
//            out["defaultNewTabExperience"] = newTabChoice as AnyObject?
//        }
//
//        if let chosenEmailClient = profile.prefs.stringForKey(PrefsKeys.KeyMailToOption) {
//            out["defaultMailClient"] = chosenEmailClient as AnyObject?
//        }

        // TODO: Add pref items
//                telemetryConfig.measureUserDefaultsSetting(forKey: SearchEngineManager.prefKeyEngine, withDefaultValue: defaultSearchEngineProvider)

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
    }
}

