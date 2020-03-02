/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared

struct ContentBlockingConfig {
    struct Prefs {
        static let StrengthKey = "prefkey.trackingprotection.strength"
        static let EnabledKey = "prefkey.trackingprotection.normalbrowsing"
    }

    struct Defaults {
        static let NormalBrowsing = !AppInfo.isChinaEdition
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
class FirefoxTabContentBlocker: TabContentBlocker, TabContentScript {
    let userPrefs: Prefs

    class func name() -> String {
        return "TrackingProtectionStats"
    }

    var isUserEnabled: Bool? {
        didSet {
            guard let tab = tab as? Tab else { return }
            setupForTab()
            TabEvent.post(.didChangeContentBlocking, for: tab)
            tab.reload()
        }
    }

    override var isEnabled: Bool {
        if let enabled = isUserEnabled {
            return enabled
        }

        return isEnabledInPref
    }

    var isEnabledInPref: Bool {
        return userPrefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
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
        let rules = BlocklistFileName.listsForMode(strict: blockingStrengthPref == .strict)
        ContentBlocker.shared.setupTrackingProtection(forTab: tab, isEnabled: isEnabled, rules: rules)
    }

    @objc override func notifiedTabSetupRequired() {
        setupForTab()
        if let tab = tab as? Tab {
            TabEvent.post(.didChangeContentBlocking, for: tab)
        }
    }

    override func currentlyEnabledLists() -> [BlocklistFileName] {
        return BlocklistFileName.listsForMode(strict: blockingStrengthPref == .strict)
    }

    override func notifyContentBlockingChanged() {
        guard let tab = tab as? Tab else { return }
        TabEvent.post(.didChangeContentBlocking, for: tab)
    }

    func noImageMode(enabled: Bool) {
        guard let tab = tab else { return }
        ContentBlocker.shared.noImageMode(enabled: enabled, forTab: tab)
    }
}

// Static methods to access user prefs for tracking protection
extension FirefoxTabContentBlocker {
    static func setTrackingProtection(enabled: Bool, prefs: Prefs) {
        let key = ContentBlockingConfig.Prefs.EnabledKey
        prefs.setBool(enabled, forKey: key)
        ContentBlocker.shared.prefsChanged()
    }

    static func isTrackingProtectionEnabled(prefs: Prefs) -> Bool {
        return prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
    }

    static func toggleTrackingProtectionEnabled(prefs: Prefs) {
        let isEnabled = FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: prefs)
        setTrackingProtection(enabled: !isEnabled, prefs: prefs)
    }
}
