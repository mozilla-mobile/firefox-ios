/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdjustSdk

enum AdjustEventName: String {
    case browse = "Browse"                                     // When the user opens a url
    case search = "Search"                                     // When the user does a search
    case clear = "Clear"                                       // When the user erases the browsing history
    case openFirefox = "OpenInFirefox"                         // When the user opens the page in Firefox
    case openSafari = "OpenInSafari"                           // When the user opens the page in Safari
    case openFirefoxInstall = "OpenFirefoxInstall"             // When the user opens the App Store page for Firefox
    case openSystemShare = "OpenSystemShare"                   // When the user opens the system share menu
    case enableSafariIntegration = "EnableSafariIntegration"   // When the user enables the Safari blocklist
    case disableSafariIntegration = "DisableSafariIntegration" // When the user disables the Safari blocklist
    case enableBlockAds = "EnableBlockAds"                     // When the user enables Block Ad Trackers
    case disableBlockAds = "DisableBlockAds"                   // When the user disables Block Ad Trackers
    case enableBlockAnalytics = "EnableBlockAnalytics"         // When the user enables Block Analytics Trackers
    case disableBlockAnalytics = "DisableBlockAnalytics"       // When the user disabled Block Analytics Trackers
    case enableBlockSocial = "EnableBlockSocial"               // When the user enables Block Social Trackers
    case disableBlockSocial = "DisableBlockSocial"             // When the user disables Block Social Trackers
    case enableBlockOther = "EnableBlockOther"                 // When the user enables Block Other Content Trackers
    case disableBlockOther = "DisableBlockOther"               // When the user disables Block Other Content Trackers
    case enableBlockFonts = "EnableBlockFonts"                 // When the user enables Block Web Fonts
    case disableBlockFonts = "DisableBlockFonts"               // When the user disables Block Web Fonts
}

private let AdjustAppTokenKey = "AppToken"
private let AdjustEventsKey = "Events"

private enum AdjustEnvironment: String {
    case sandbox = "sandbox"
    case production = "production"
}

private struct AdjustSettings {
    var appToken: String
    var environment: AdjustEnvironment
    var events: [AdjustEventName: String]

    init?(contentsOf url: URL) {
        guard let config = NSDictionary(contentsOf: url), let appToken = config.object(forKey: AdjustAppTokenKey) as? String, let events = config.object(forKey: AdjustEventsKey) as? [String: String] else {
            return nil
        }

        var eventMappings = [AdjustEventName: String]()
        for (name, token) in events {
            guard let eventName = AdjustEventName(rawValue: name) else {
                assertionFailure("Event <\(name)> from settings plist not found in enum")
                continue
            }
            eventMappings[eventName] = token
        }

        self.appToken = appToken
        #if DEBUG
            self.environment = AdjustEnvironment.sandbox
        #else
            self.environment = AdjustEnvironment.production
        #endif
        self.events = eventMappings
    }
}

class AdjustIntegration {
    fileprivate static var adjustSettings: AdjustSettings?

    public static func applicationDidFinishLaunching() {
        if let url = Bundle.main.url(forResource: AppInfo.config.adjustFile, withExtension: "plist"),
           let settings = AdjustSettings(contentsOf: url) {
            adjustSettings = settings

            let config = ADJConfig(appToken: settings.appToken, environment: settings.environment.rawValue)
            #if DEBUG
                config?.logLevel = ADJLogLevelDebug
            #endif

            Adjust.appDidLaunch(config)
        }
    }

    public static var enabled: Bool {
        get {
            return Adjust.isEnabled()
        }
        set {
            Adjust.setEnabled(newValue)
        }
    }

    public static func track(eventName: AdjustEventName) {
        if Adjust.isEnabled() {
            guard let settings = adjustSettings, let eventToken = settings.events[eventName] else {
                assertionFailure("Adjust not initialized or event <\(eventName.rawValue)> was not found in the settings")
                return
            }
            Adjust.trackEvent(ADJEvent(eventToken: eventToken))
        }
    }
}
