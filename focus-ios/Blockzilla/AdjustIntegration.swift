/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdjustSdk

enum AdjustEventName: String {
    case browse = "Browse"
    case search = "Search"
    case clear = "Clear"
    case openFirefox = "OpenInFirefox"
    case openSafari = "OpenInSafari"
    case enableSafariIntegration = "EnableSafariIntegration"
    case disableSafariIntegration = "DisableSafariIntegration"
    case enableBlockAds = "EnableBlockAds"
    case disableBlockAds = "DisableBlockAds"
    case enableBlockAnalytics = "EnableBlockAnalytics"
    case disableBlockAnalytics = "DisableBlockAnalytics"
    case enableBlockSocial = "EnableBlockSocial"
    case disableBlockSocial = "DisableBlockSocial"
    case enableBlockOther = "EnableBlockOther"
    case disableBlockOther = "DisableBlockOther"
    case enableBlockFonts = "EnableBlockFonts"
    case disableBlockFonts = "DisableBlockFonts"
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
        if let url = Bundle.main.url(forResource: AppInfo.isFocus ? "Adjust-Focus" : "Adjust-Klar", withExtension: "plist"),
           let settings = AdjustSettings(contentsOf: url) {
            adjustSettings = settings

            let config = ADJConfig(appToken: settings.appToken, environment: settings.environment.rawValue)
            #if DEBUG
                config?.logLevel = ADJLogLevelDebug
            #endif

            Adjust.appDidLaunch(config)
        }
    }

    public static func disable() {
        Adjust.setEnabled(false)
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
