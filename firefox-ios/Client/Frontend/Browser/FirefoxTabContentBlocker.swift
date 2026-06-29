// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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

extension BlockingStrength {
    var settingStatus: String {
        switch self {
        case .basic:
            return .TrackingProtectionOptionBlockListLevelStandardStatus
        case .strict:
            return .TrackingProtectionOptionBlockListLevelStrict
        }
    }

    var settingTitle: String {
        switch self {
        case .basic:
            return .TrackingProtectionOptionBlockListLevelStandard
        case .strict:
            return .TrackingProtectionOptionBlockListLevelStrict
        }
    }

    var settingSubtitle: String {
        switch self {
        case .basic:
            return .TrackingProtectionStandardLevelDescription
        case .strict:
            return .TrackingProtectionStrictLevelDescription
        }
    }

    static func accessibilityId(for strength: BlockingStrength) -> String {
        switch strength {
        case .basic:
            return AccessibilityIdentifiers.Settings.TrackingProtection.basic
        case .strict:
            return AccessibilityIdentifiers.Settings.TrackingProtection.strict
        }
    }
}

/// Firefox-specific implementation of tab content blocking.
@MainActor
final class FirefoxTabContentBlocker: TabContentBlocker, TabContentScript, FeatureFlaggable {
    let userPrefs: Prefs

    /// Whether the ad-blocker list (fetched from Remote Settings) should be applied to tabs.
    /// Gated behind the `.adBlocker` feature flag and the user's Block Ads setting.
    private var isAdBlockingEnabled: Bool {
        return featureFlagsProvider.isEnabled(.adBlocker) && (userPrefs.boolForKey(PrefsKeys.BlockAds) ?? false)
    }

    /// The content blocking rules to apply for the current tab: the standard tracking protection
    /// lists (only when TP is enabled) plus the ad-blocker list when enabled. The ad-blocker list is
    /// independent of tracking protection — it applies even when TP is off.
    private func currentRules() -> [String] {
        var rules = isEnabled ? BlocklistFileName.listsForMode(strict: blockingStrengthPref == .strict) : []
        if isAdBlockingEnabled {
            rules.append(ContentBlocker.adBlockerRuleIdentifier)
        }
        return rules
    }

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

    func setupForTab(completion: (() -> Void)? = nil) {
        guard let tab = tab else { return }
        let rules = currentRules()
        logger.log("Setup tracking protection for tab: \(tab)", level: .info, category: .adblock)
        // The ad-blocker rule list is independent of tracking protection — it must apply even when
        // TP is off, so the content blocker is considered enabled if either is on.
        ContentBlocker.shared.setupTrackingProtection(
            forTab: tab,
            isEnabled: isEnabled || isAdBlockingEnabled,
            rules: rules,
            completion: completion
        )
    }

    override func notifiedTabSetupRequired() {
        guard let tab = self.tab as? Tab else { return }
        self.logger.log("Notified tab setup required", level: .info, category: .adblock)
        self.setupForTab(completion: { tab.reload() })
        TabEvent.post(.didChangeContentBlocking, for: tab)
    }

    override func currentlyEnabledLists() -> [String] {
        return currentRules()
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
