/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

fileprivate let NotificationContentBlockerUpdateNeeded = "NotificationContentBlockerUpdateNeeded"

@available(iOS 11.0, *)
class ContentBlockerHelper {
    static let PrefKeyEnabledState = "prefkey.trackingprotection.enabled"
    static let PrefKeyStrength = "prefkey.trackingprotection.strength"
    fileprivate let blocklistBasic = ["disconnect-advertising", "disconnect-analytics", "disconnect-social"]
    fileprivate let blocklistStrict = ["disconnect-content", "web-fonts"]
    fileprivate let ruleStore: WKContentRuleListStore
    fileprivate weak var tab: Tab?
    fileprivate weak var profile: Profile?

    static var blockImagesRule: WKContentRuleList?

    enum TrackingProtectionUserOverride {
        case disallowUserOverride // Option is not offered if tracking protection is off in prefs
        case allowedButNotSet
        case forceEnabled
        case forceDisabled
    }

    fileprivate var prefOverrideTrackingProtectionEnabled: Bool?
    var userOverrideForTrackingProtection: TrackingProtectionUserOverride {
        if !trackingProtectionEnabledInSettings {
            return .disallowUserOverride
        }
        guard let enabled = prefOverrideTrackingProtectionEnabled else {
            return .allowedButNotSet
        }
        return enabled ? .forceEnabled : .forceDisabled
    }

    // Raw values are stored to prefs, be careful changing them.
    enum EnabledState: String {
        case on
        case onInPrivateBrowsing
        case off

        var settingTitle: String {
            switch self {
            case .on:
                return Strings.TrackingProtectionOptionAlwaysOn
            case .onInPrivateBrowsing:
                return Strings.TrackingProtectionOptionOnInPrivateBrowsing
            case .off:
                return Strings.TrackingProtectionOptionAlwaysOff
            }
        }

        static let allOptions: [EnabledState] = [.on, .onInPrivateBrowsing, .off]
    }

    // Raw values are stored to prefs, be careful changing them.
    enum BlockingStrength: String {
        case basic
        case strict

        var settingTitle: String {
            switch self {
            case .basic:
                return Strings.TrackingProtectionOptionBlockListTypeBasic
            case .strict:
                return Strings.TrackingProtectionOptionBlockListTypeStrict
            }
        }

        var subtitle: String {
            switch self {
            case .basic:
                return Strings.TrackingProtectionOptionBlockListTypeBasicDescription
            case .strict:
                return Strings.TrackingProtectionOptionBlockListTypeStrictDescription
            }
        }

        static let allOptions: [BlockingStrength] = [.basic, .strict]
    }

    static func prefsChanged() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationContentBlockerUpdateNeeded), object: nil)
    }

    class func name() -> String {
        return "ContentBlockerHelper"
    }

    private static var heavyInitHasRunOnce = false

    init(tab: Tab, profile: Profile) {
        self.ruleStore = WKContentRuleListStore.default()
        self.tab = tab
        self.profile = profile

        if ContentBlockerHelper.heavyInitHasRunOnce {
            return
        }
        ContentBlockerHelper.heavyInitHasRunOnce = true

        removeOldListsByDateFromStore() {
            self.removeOldListsByNameFromStore() {
                self.compileListsNotInStore(completion: {})
            }
        }

        let blockImages = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]".replacingOccurrences(of: "'", with: "\"")
        ruleStore.compileContentRuleList(forIdentifier: "images", encodedContentRuleList: blockImages) {
            rule, error in
            assert(rule != nil && error == nil)
            ContentBlockerHelper.blockImagesRule = rule
        }
    }

    func setupForWebView() {
        NotificationCenter.default.addObserver(self, selector: #selector(ContentBlockerHelper.updateTab), name: NSNotification.Name(rawValue: NotificationContentBlockerUpdateNeeded), object: nil)
        addActiveRulesToTab()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateTab() {
        addActiveRulesToTab()
    }

    func overridePrefsAndReloadTab(enableTrackingProtection: Bool) {
        prefOverrideTrackingProtectionEnabled = enableTrackingProtection
        updateTab()
        tab?.reload()
    }

    fileprivate var blockingStrengthPref: BlockingStrength {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? ""
        return BlockingStrength(rawValue: pref) ?? .basic
    }

    fileprivate var enabledStatePref: EnabledState {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? ""
        return EnabledState(rawValue: pref) ?? .onInPrivateBrowsing
    }

    fileprivate var trackingProtectionEnabledInSettings: Bool {
        switch enabledStatePref {
        case .off:
            return false
        case .on:
            return true
        case .onInPrivateBrowsing:
            return tab?.isPrivate ?? false
        }
    }

    fileprivate func addActiveRulesToTab() {
        removeTrackingProtectionFromTab()

        if userOverrideForTrackingProtection == .forceDisabled {
            // User can temporarily override the settings to turn TP on or off.
            return
        } else if !trackingProtectionEnabledInSettings {
            return
        }
        let rules = blocklistBasic + (blockingStrengthPref == .strict ? blocklistStrict : [])
        for name in rules {
            ruleStore.lookUpContentRuleList(forIdentifier: name) { rule, error in
                guard let rule = rule else {
                    let msg = "lookUpContentRuleList for \(name):  \(error?.localizedDescription ?? "empty rules")"
                    Sentry.shared.send(message: "Content blocker error", tag: .general, description: msg)
                    return
                }
                self.addToTab(contentRuleList: rule)
            }
        }
    }

    func removeTrackingProtectionFromTab() {
        guard let tab = tab else { return }
        tab.webView?.configuration.userContentController.removeAllContentRuleLists()

        if let rule = ContentBlockerHelper.blockImagesRule, tab.noImageMode {
            addToTab(contentRuleList: rule)
        }
    }

    fileprivate func addToTab(contentRuleList: WKContentRuleList) {
        tab?.webView?.configuration.userContentController.add(contentRuleList)
    }

    func noImageMode(enabled: Bool) {
        guard let rule = ContentBlockerHelper.blockImagesRule else { return }

        if enabled {
            addToTab(contentRuleList: rule)
        } else {
            tab?.webView?.configuration.userContentController.remove(rule)
        }

        // Async required here to ensure remove() call is processed.
        DispatchQueue.main.async() {
            self.tab?.webView?.evaluateJavaScript("window.__firefox__.NoImageMode.setEnabled(\(enabled))", completionHandler: nil)
        }
    }
}

// MARK: Private initialization code
// The rule store can compile JSON rule files into a private format which is cached on disk.
// On app boot, we need to check if the ruleStore's data is out-of-date, or if the names of the rule files
// no longer match. Finally, any JSON rule files that aren't in the ruleStore need to be compiled and stored in the
// ruleStore.
@available(iOS 11, *)
extension ContentBlockerHelper {
    fileprivate func loadJsonFromBundle(forResource file: String, completion: @escaping (_ jsonString: String) -> Void) {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: file, ofType: "json"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String else {
                    return
            }
            DispatchQueue.main.async {
                completion(source)
            }
        }
    }

    fileprivate func lastModifiedSince1970(forFileAtPath path: String) -> Timestamp? {
        do {
            let url = URL(fileURLWithPath: path)
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let date = attr[FileAttributeKey.modificationDate] as? Date else { return nil }
            return UInt64(1000.0 * date.timeIntervalSince1970)
        } catch {
            return nil
        }
    }

    fileprivate func dateOfMostRecentBlockerFile() -> Timestamp {
        let blocklists = blocklistBasic + blocklistStrict
        return blocklists.reduce(Timestamp(0)) { result, filename in
            guard let path = Bundle.main.path(forResource: filename, ofType: "json") else { return result }
            let date = lastModifiedSince1970(forFileAtPath: path) ?? 0
            return date > result ? date : result
        }
    }

    fileprivate func removeAllRulesInStore(completion: @escaping () -> Void) {
        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }
            let deferreds: [Deferred<Void>] = available.map { filename in
                let result = Deferred<Void>()
                self.ruleStore.removeContentRuleList(forIdentifier: filename) { _ in
                   result.fill()
                }
                return result
            }
            all(deferreds).uponQueue(.main) { _ in
                completion()
            }
        }
    }

    // If any blocker files are newer than the date saved in prefs,
    // remove all the content blockers and reload them.
    fileprivate func removeOldListsByDateFromStore(completion: @escaping () -> Void) {
        let fileDate = self.dateOfMostRecentBlockerFile()
        let prefsNewestDate = profile?.prefs.longForKey("blocker-file-date") ?? 0
        if prefsNewestDate < 1 || fileDate <= prefsNewestDate {
            completion()
            return
        }

        profile?.prefs.setTimestamp(fileDate, forKey: "blocker-file-date")
        self.removeAllRulesInStore() {
            completion()
        }
    }

    fileprivate func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }

            let blocklists = self.blocklistBasic + self.blocklistStrict
            for contentRuleIdentifier in available {
                if !blocklists.contains(where: { $0 == contentRuleIdentifier }) {
                    noMatchingIdentifierFoundForRule = true
                    break
                }
            }

            let fileDate = self.dateOfMostRecentBlockerFile()
            let prefsNewestDate = self.profile?.prefs.timestampForKey("blocker-file-date") ?? 0
            if prefsNewestDate > 0 && fileDate <= prefsNewestDate && !noMatchingIdentifierFoundForRule {
                completion()
                return
            }
            self.profile?.prefs.setTimestamp(fileDate, forKey: "blocker-file-date")

            self.removeAllRulesInStore {
                completion()
            }
        }
    }

    fileprivate func compileListsNotInStore(completion: @escaping () -> Void) {
        let blocklists = blocklistBasic + blocklistStrict
        let deferreds: [Deferred<Void>] = blocklists.map { filename in
            let result = Deferred<Void>()
            ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                if contentRuleList != nil {
                    result.fill()
                    return
                }
                self.loadJsonFromBundle(forResource: filename) { jsonString in
                    self.ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: jsonString) { _, _ in
                        result.fill()
                    }
                }
            }
            return result
        }

        all(deferreds).uponQueue(.main) { _ in
            completion()
        }
    }
}
