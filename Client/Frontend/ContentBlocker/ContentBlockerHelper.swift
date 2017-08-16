/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared

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
    enum EnabledOption: String {
        case on = "option-on"
        case onInPrivateBrowsing = "option-on-private-browsing-only"
        case off = "option-off"

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

        static let allOptions: [EnabledOption] = [.on, .onInPrivateBrowsing, .off]
    }

    // Raw values are stored to prefs, be careful changing them.
    enum StrengthOption: String {
        case basic = "option-basic"
        case strict = "option-strict"

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

        static let allOptions: [StrengthOption] = [.basic, .strict]
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
            print("WKContentRuleListStore unavailable.")
            assert(false)
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

        var wasRuleListChangedDuringInit = false
        removeOldListsByDateFromStore() { isListChanged in
            wasRuleListChangedDuringInit = isListChanged

            self.removeOldListsByNameFromStore() { isListChanged in
                wasRuleListChangedDuringInit = wasRuleListChangedDuringInit || isListChanged

                self.compileListsNotInStore() { isListChanged in
                    wasRuleListChangedDuringInit = wasRuleListChangedDuringInit || isListChanged

                    if wasRuleListChangedDuringInit {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationContentBlockerReloadNeeded), object: nil)
                    }
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func readStrengthPref() -> StrengthOption {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyStrength) ?? ""
        return StrengthOption(rawValue: pref) ?? .basic
    }

    fileprivate func readEnabledPref() -> EnabledOption {
        let pref = profile?.prefs.stringForKey(ContentBlockerHelper.PrefKeyEnabledState) ?? ""
        return EnabledOption(rawValue: pref) ?? .onInPrivateBrowsing
    }

    @objc func reloadTab() {
        addActiveRulesToTab(reloadTab: true)
    }

    fileprivate func addActiveRulesToTab(reloadTab: Bool) {
        guard let ruleStore = ruleStore else { return }
        let rules = blocklistBasic + (readStrengthPref() == .strict ? blocklistStrict : [])
        let enabledMode = readEnabledPref()
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

        switch readEnabledPref() {
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

// Private initialization code
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

    fileprivate func lastModifiedSince1970(path: String) -> TimeInterval? {
        do {
            let url = URL(fileURLWithPath: path)
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            let date = attr[FileAttributeKey.modificationDate] as? Date
            return date?.timeIntervalSince1970
        } catch {
            return nil
        }
    }

    fileprivate func dateOfMostRecentBlockerFile() -> TimeInterval {
        let blocklists = blocklistBasic + blocklistStrict
        return blocklists.reduce(TimeInterval(0)) { result, filename in
            guard let path = Bundle.main.path(forResource: filename, ofType: "json") else { return result }
            let date = lastModifiedSince1970(path: path) ?? 0
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
            var completionCount = 0
            available.forEach {
                ruleStore.removeContentRuleList(forIdentifier: $0) { _ in
                    completionCount += 1
                    if completionCount == available.count {
                        completion()
                    }
                }
            }
        }
    }

    // If any blocker files are newer than the date saved in prefs,
    // remove all the content blockers and reload them.
    // Pass true to completion block if the rule store was modified.
    fileprivate func removeOldListsByDateFromStore(completion: @escaping (_ modified: Bool) -> Void) {
        let fileDate = self.dateOfMostRecentBlockerFile()
        let prefsNewestDate = UserDefaults.standard.double(forKey: "blocker-file-date")
        if prefsNewestDate < 1 || fileDate <= prefsNewestDate {
            completion(false)
            return
        }

        UserDefaults.standard.set(fileDate, forKey: "blocker-file-date")
        self.removeAllRulesInStore() {
            completion(true)
        }
    }

    // Pass true to completion block if the rule store was modified.
    fileprivate func removeOldListsByNameFromStore(completion: @escaping (_ modified: Bool) -> Void) {
        guard let ruleStore = ruleStore else { return }
        var noMatchingIdentifierFoundForRule = false

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion(false)
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
            let prefsNewestDate = UserDefaults.standard.double(forKey: "blocker-file-date")
            if fileDate <= prefsNewestDate && !noMatchingIdentifierFoundForRule {
                completion(false)
                return
            }
            UserDefaults.standard.set(fileDate, forKey: "blocker-file-date")

            self.removeAllRulesInStore() {
                completion(true)
            }
        }
    }

    // Pass true to completion block if the rule store was modified.
    fileprivate func compileListsNotInStore(completion: @escaping (_ modified: Bool) -> Void) {
        guard let ruleStore = ruleStore else { return }
        let dispatchGroup = DispatchGroup()
        var wasCompilationNeeded = false
        for filename in blocklistBasic + blocklistStrict {
            dispatchGroup.enter()
            ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                if contentRuleList != nil {
                    dispatchGroup.leave()
                    return
                }
                wasCompilationNeeded = true
                self.loadJsonFromBundle(forResource: filename) { jsonString in
                    ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: jsonString) { _, _ in
                        dispatchGroup.leave()
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(wasCompilationNeeded)
        }
    }
}
