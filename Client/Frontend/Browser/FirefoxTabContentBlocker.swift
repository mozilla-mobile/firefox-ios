/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Deferred
import Shared

struct ContentBlockingConfig {
    struct Prefs {
        static let StrengthKey = "prefkey.trackingprotection.strength"
        static let NormalBrowsingEnabledKey = "prefkey.trackingprotection.normalbrowsing"
        static let PrivateBrowsingEnabledKey = "prefkey.trackingprotection.privatebrowsing"
    }

    struct Defaults {
        static let NormalBrowsing = !BrowserProfile.isChinaEdition
        static let PrivateBrowsing = !BrowserProfile.isChinaEdition
    }
}

enum BlockingStrength: String {
    case basic
    case strict

    static let allOptions: [BlockingStrength] = [.basic, .strict]
}

/**
 Firefox-specific implementation of tab content blocking.
 */
@available(iOS 11.0, *)
class FirefoxTabContentBlocker: TabContentBlocker, TabContentScript {
    let userPrefs: Prefs

    class func name() -> String {
        return "TrackingProtectionStats"
    }

    var isUserEnabled: Bool? {
        didSet {
            guard let tab = tab as? Tab else { return }
            setupForTab()
            NotificationCenter.default.post(name: .didChangeContentBlocking, object: nil, userInfo: ["tab": tab])
            tab.reload()
        }
    }

    override var isEnabled: Bool {
        if let enabled = isUserEnabled {
            return enabled
        }
        guard let tab = tab as? Tab else { return false }
        return tab.isPrivate ? isEnabledInPrivateBrowsing : isEnabledInNormalBrowsing
    }

    var isEnabledInNormalBrowsing: Bool {
        return userPrefs.boolForKey(ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
    }

    var isEnabledInPrivateBrowsing: Bool {
        return userPrefs.boolForKey(ContentBlockingConfig.Prefs.PrivateBrowsingEnabledKey) ?? ContentBlockingConfig.Defaults.PrivateBrowsing
    }

    var blockingStrengthPref: BlockingStrength {
        return userPrefs.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap(BlockingStrength.init) ?? .basic
    }

    init(tab: ContentBlockerTab, prefs: Prefs) {
        userPrefs = prefs
        super.init(tab: tab)
        setupForTab()
    }

    func setupForTab() {
        guard let tab = tab else { return }
        let rules = BlocklistName.forStrictMode(isOn: blockingStrengthPref == .strict)
        ContentBlocker.shared.setupTrackingProtection(forTab: tab, isEnabled: isEnabled, rules: rules)
    }

    @objc override func notifiedTabSetupRequired() {
        setupForTab()
    }

    override func currentlyEnabledLists() -> [BlocklistName] {
        return BlocklistName.forStrictMode(isOn: blockingStrengthPref == .strict)
    }

    func noImageMode(enabled: Bool) {
        guard let tab = tab else { return }
        ContentBlocker.shared.noImageMode(enabled: enabled, forTab: tab)
    }
}

// Static methods to access user prefs for tracking protection
extension FirefoxTabContentBlocker {
    static func setTrackingProtection(enabled: Bool, prefs: Prefs, tabManager: TabManager) {
        guard let isPrivate = tabManager.selectedTab?.isPrivate else { return }
        let key = isPrivate ? ContentBlockingConfig.Prefs.PrivateBrowsingEnabledKey : ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey
        prefs.setBool(enabled, forKey: key)
        ContentBlocker.shared.prefsChanged()
    }

    static func isTrackingProtectionEnabled(tabManager: TabManager) -> Bool {
        guard let blocker = tabManager.selectedTab?.contentBlocker as? FirefoxTabContentBlocker else { return false }
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        return isPrivate ? blocker.isEnabledInPrivateBrowsing : blocker.isEnabledInNormalBrowsing
    }

    static func toggleTrackingProtectionEnabled(prefs: Prefs, tabManager: TabManager) {
        let isEnabled = FirefoxTabContentBlocker.isTrackingProtectionEnabled(tabManager: tabManager)
        setTrackingProtection(enabled: !isEnabled, prefs: prefs, tabManager: tabManager)
    }
}
