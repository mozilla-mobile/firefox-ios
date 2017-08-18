/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

fileprivate let NotificationContentBlockerReloadNeeded = "NotificationContentBlockerReloadNeeded"

@available(iOS 11.0, *)
class ContentBlockerHelper {
    static let PrefKeyEnabledState = "prefkey.trackingprotection.enabled"
    static let PrefKeyStrength = "prefkey.trackingprotection.strength"
    fileprivate let blocklistBasic = ["disconnect-advertising", "disconnect-analytics", "disconnect-social"]
    fileprivate let blocklistStrict = ["disconnect-content", "web-fonts"]
    fileprivate let ruleStore: WKContentRuleListStore?
    fileprivate weak var tab: Tab?
    fileprivate weak var profile: Profile?

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
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationContentBlockerReloadNeeded), object: nil)
    }

    class func name() -> String {
        return "ContentBlockerHelper"
    }

    private static var heavyInitHasRunOnce = false

    init(tab: Tab, profile: Profile) {
        self.ruleStore = WKContentRuleListStore.default()
        if self.ruleStore == nil {
            assert(false, "WKContentRuleListStore unavailable.")
            return
        }

        self.tab = tab
        self.profile = profile

        NotificationCenter.default.addObserver(self, selector: #selector(ContentBlockerHelper.reloadTab), name: NSNotification.Name(rawValue: NotificationContentBlockerReloadNeeded), object: nil)

        addActiveRulesToTab(reloadTab: false)

        if ContentBlockerHelper.heavyInitHasRunOnce {
            return
        }
        ContentBlockerHelper.heavyInitHasRunOnce = true

        removeOldListsByDateFromStore() {
            self.removeOldListsByNameFromStore() {
                self.compileListsNotInStore(completion: {})
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate var blockingStrengthPref: BlockingStrength {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? ""
        return BlockingStrength(rawValue: pref) ?? .basic
    }

    fileprivate var enabledStatePref: EnabledState {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? ""
        return EnabledState(rawValue: pref) ?? .onInPrivateBrowsing
    }

    @objc func reloadTab() {
        addActiveRulesToTab(reloadTab: true)
    }

    fileprivate func addActiveRulesToTab(reloadTab: Bool) {
        guard let ruleStore = ruleStore else { return }
        let rules = blocklistBasic + (blockingStrengthPref == .strict ? blocklistStrict : [])
        let enabledMode = enabledStatePref
        removeAllFromTab()

        func addRules() {
            var completed = 0
            for name in rules {
                ruleStore.lookUpContentRuleList(forIdentifier: name) { rule, error in
                    self.addToTab(contentRuleList: rule, error: error)
                    completed += 1
                    if reloadTab && completed == rules.count {
                        self.tab?.reload()
                    }
                }
            }
        }

        switch enabledStatePref {
        case .off:
            if reloadTab {
                self.tab?.reload()
            }
            return
        case .on:
            addRules()
        case .onInPrivateBrowsing:
            if tab?.isPrivate ?? false {
                addRules()
            } else {
                self.tab?.reload()
            }
        }
    }

    func removeAllFromTab() {
        tab?.webView?.configuration.userContentController.removeAllContentRuleLists()
    }

    fileprivate func addToTab(contentRuleList: WKContentRuleList?, error: Error?) {
        if let rules = contentRuleList {
            tab?.webView?.configuration.userContentController.add(rules)
        } else {
            print("Content blocker load error: " + (error?.localizedDescription ?? "empty rules"))
            assert(false)
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
        guard let ruleStore = ruleStore else { return }

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }
            let deferreds: [Deferred<Void>] = available.map { filename in
                let result = Deferred<Void>()
                ruleStore.removeContentRuleList(forIdentifier: filename) { _ in
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
        guard let ruleStore = ruleStore else { return }
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

    // Pass true to completion block if the rule store was modified.
    fileprivate func compileListsNotInStore(completion: @escaping () -> Void) {
        guard let ruleStore = ruleStore else { return }
        let blocklists = blocklistBasic + blocklistStrict
        let deferreds: [Deferred<Void>] = blocklists.map { filename in
            let result = Deferred<Void>()
            ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                if contentRuleList != nil {
                    result.fill()
                    return
                }
                self.loadJsonFromBundle(forResource: filename) { jsonString in
                    ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: jsonString) { _, _ in
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
