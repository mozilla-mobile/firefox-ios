/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

extension Notification.Name {
    fileprivate static let ContentBlockerPrefsChanged = Notification.Name("ContentBlockerPrefsChanged")
}

enum BlocklistName: String {
    case advertising = "disconnect-advertising"
    case analytics = "disconnect-analytics"
    case content = "disconnect-content"
    case social = "disconnect-social"

    var filename: String { return self.rawValue }

    static var all: [BlocklistName] { return [.advertising, .analytics, .content, .social] }
    static var basic: [BlocklistName] { return [.advertising, .analytics, .social] }
    static var strict: [BlocklistName] { return [.content] }

    static func forStrictMode(isOn: Bool) -> [BlocklistName] {
        return BlocklistName.basic + (isOn ? BlocklistName.strict : [])
    }
}

struct ContentBlockingConfig {
    struct Prefs {
        static let StrengthKey = "prefkey.trackingprotection.strength"
        static let NormalBrowsingEnabledKey = "prefkey.trackingprotection.normalbrowsing"
        static let PrivateBrowsingEnabledKey = "prefkey.trackingprotection.privatebrowsing"
    }

    struct Defaults {
        static let NormalBrowsing = true
        static let PrivateBrowsing = true
    }
}

struct NoImageModeDefaults {
    static let Script = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]".replacingOccurrences(of: "'", with: "\"")
    static let ScriptName = "images"
}

enum BlockingStrength: String {
    case basic
    case strict

    static let allOptions: [BlockingStrength] = [.basic, .strict]
}

@available(iOS 11.0, *)
class ContentBlockerHelper {
    var stats = TPPageStats()
    static var whitelistedDomains = Set<String>()

    let ruleStore: WKContentRuleListStore = WKContentRuleListStore.default()
    private weak var tab: Tab?
    private(set) var userPrefs: Prefs?

    var isUserEnabled: Bool? {
        didSet {
            updateTab()
            tab?.reload()
        }
    }

    var isEnabled: Bool {
        if let enabled = isUserEnabled {
            return enabled
        }
        guard let tab = tab else { return false }
        return tab.isPrivate ? isEnabledInPrivateBrowsing : isEnabledInNormalBrowsing
    }

    var isEnabledInNormalBrowsing: Bool {
        return userPrefs?.boolForKey(ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing
    }

    var isEnabledInPrivateBrowsing: Bool {
        return userPrefs?.boolForKey(ContentBlockingConfig.Prefs.PrivateBrowsingEnabledKey) ?? ContentBlockingConfig.Defaults.PrivateBrowsing
    }

    var blockingStrengthPref: BlockingStrength {
        return userPrefs?.stringForKey(ContentBlockingConfig.Prefs.StrengthKey).flatMap(BlockingStrength.init) ?? .basic
    }

    static private var blockImagesRule: WKContentRuleList?
    static var heavyInitHasRunOnce = false

    // Only set and used in UI test
    static weak var testInstance: ContentBlockerHelper?

    init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.userPrefs = profile.prefs

        if AppConstants.IsRunningTest {
            ContentBlockerHelper.testInstance = self
        }

        if ContentBlockerHelper.heavyInitHasRunOnce {
            return
        }

        migrateLegacyUserPrefs()

        // Read the whitelist at startup
        if let list = readWhitelistFile() {
            // Convert array to a Set()
            ContentBlockerHelper.whitelistedDomains = Set(list.map { $0 })
        }

        removeOldListsByDateFromStore() {
            self.removeOldListsByNameFromStore() {
                self.compileListsNotInStore {
                    ContentBlockerHelper.heavyInitHasRunOnce = true
                    self.setupTabTrackingProtection(forUrl: self.tab?.webView?.url)
                }
            }
        }

        let blockImages = NoImageModeDefaults.Script
        ruleStore.compileContentRuleList(forIdentifier: NoImageModeDefaults.ScriptName, encodedContentRuleList: blockImages) { rule, error in
            assert(rule != nil && error == nil)
            ContentBlockerHelper.blockImagesRule = rule
        }
    }

    func setupForWebView() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTab), name: .ContentBlockerPrefsChanged, object: nil)
        setupTabTrackingProtection(forUrl: tab?.webView?.url)
    }

    class func prefsChanged() {
        // This class func needs to notify all the active instances of ContentBlockerHelper to update.
        NotificationCenter.default.post(name: .ContentBlockerPrefsChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateTab() {
        setupTabTrackingProtection(forUrl: tab?.webView?.url)
    }

    // If a user had set a pref for Tracking Protection outside of the previous defaults then make sure to honor those settings
    private func migrateLegacyUserPrefs() {
        // If a user had set PrefEnabledState to ON this means that TP was on in normal browsing
        // if a user had set PrefEnabledState to OFF this means that TP was off in both normal and private browsing
        if let legacyPref = userPrefs?.stringForKey("prefkey.trackingprotection.enabled") {
            if legacyPref == "on" {
                userPrefs?.setBool(true, forKey: ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey)
            } else if legacyPref == "off" {
                userPrefs?.setBool(false, forKey: ContentBlockingConfig.Prefs.NormalBrowsingEnabledKey)
                userPrefs?.setBool(false, forKey: ContentBlockingConfig.Prefs.PrivateBrowsingEnabledKey)
            }
            // We only need to do this once. We can wipe the old pref
            userPrefs?.removeObjectForKey("prefkey.trackingprotection.enabled")
        }
    }

    private var isTPInstalledForTab = false

    // Function to install or remove TP for a tab, if a main doc URL is available on the tab, it can be checked for whitelisting.
    func setupTabTrackingProtection(forUrl url: URL?) {
        if !ContentBlockerHelper.heavyInitHasRunOnce {
            return
        }

        let isInstalling = isEnabled && (url != nil && !ContentBlockerHelper.isWhitelisted(url: url!))
        if isInstalling == isTPInstalledForTab {
            return
        }
        isTPInstalledForTab = isInstalling

        removeTrackingProtection()

        if !isInstalling {
            return
        }

        let rules = BlocklistName.forStrictMode(isOn: blockingStrengthPref == .strict)
        for list in rules {
            let name = list.filename
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

    private func removeTrackingProtection() {
        guard let tab = tab else { return }
        tab.webView?.configuration.userContentController.removeAllContentRuleLists()

        if let rule = ContentBlockerHelper.blockImagesRule, tab.noImageMode {
            addToTab(contentRuleList: rule)
        }
    }

    private func addToTab(contentRuleList: WKContentRuleList) {
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
            self.tab?.webView?.evaluateJavaScript("window.__firefox__.NoImageMode.setEnabled(\(enabled))")
        }
    }

}

// MARK: Initialization code
// The rule store can compile JSON rule files into a private format which is cached on disk.
// On app boot, we need to check if the ruleStore's data is out-of-date, or if the names of the rule files
// no longer match. Finally, any JSON rule files that aren't in the ruleStore need to be compiled and stored in the
// ruleStore.
@available(iOS 11, *)
extension ContentBlockerHelper {
    private func loadJsonFromBundle(forResource file: String, completion: @escaping (_ jsonString: String) -> Void) {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: file, ofType: "json"),
                let source = try? String(contentsOfFile: path, encoding: .utf8) else {
                    return
            }

            DispatchQueue.main.async {
                completion(source)
            }
        }
    }

    private func lastModifiedSince1970(forFileAtPath path: String) -> Timestamp? {
        do {
            let url = URL(fileURLWithPath: path)
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let date = attr[FileAttributeKey.modificationDate] as? Date else { return nil }
            return UInt64(1000.0 * date.timeIntervalSince1970)
        } catch {
            return nil
        }
    }

    private func dateOfMostRecentBlockerFile() -> Timestamp {
        let blocklists = BlocklistName.all
        return blocklists.reduce(Timestamp(0)) { result, list in
            guard let path = Bundle.main.path(forResource: list.filename, ofType: "json") else { return result }
            let date = lastModifiedSince1970(forFileAtPath: path) ?? 0
            return date > result ? date : result
        }
    }

    func removeAllRulesInStore(completion: @escaping () -> Void) {
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
    func removeOldListsByDateFromStore(completion: @escaping () -> Void) {
        let fileDate = self.dateOfMostRecentBlockerFile()
        let prefsNewestDate = userPrefs?.longForKey("blocker-file-date") ?? 0
        if prefsNewestDate < 1 || fileDate <= prefsNewestDate {
            completion()
            return
        }

        userPrefs?.setTimestamp(fileDate, forKey: "blocker-file-date")
        self.removeAllRulesInStore() {
            completion()
        }
    }

    func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }

            let blocklists = BlocklistName.all.map { $0.filename }
            for contentRuleIdentifier in available {
                if !blocklists.contains(where: { $0 == contentRuleIdentifier }) {
                    noMatchingIdentifierFoundForRule = true
                    break
                }
            }

            let fileDate = self.dateOfMostRecentBlockerFile()
            let prefsNewestDate = self.userPrefs?.timestampForKey("blocker-file-date") ?? 0
            if prefsNewestDate > 0 && fileDate <= prefsNewestDate && !noMatchingIdentifierFoundForRule {
                completion()
                return
            }
            self.userPrefs?.setTimestamp(fileDate, forKey: "blocker-file-date")

            self.removeAllRulesInStore {
                completion()
            }
        }
    }

    func compileListsNotInStore(completion: @escaping () -> Void) {
        let blocklists = BlocklistName.all.map { $0.filename }
        let deferreds: [Deferred<Void>] = blocklists.map { filename in
            let result = Deferred<Void>()
            ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                if contentRuleList != nil {
                    result.fill()
                    return
                }
                self.loadJsonFromBundle(forResource: filename) { json in
                    self.ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: json) { rule, error in
                        if let error = error {
                            Sentry.shared.send(message: "Content blocker error", tag: .general, description: error.localizedDescription)
                            assert(false)
                        }
                        assert(rule != nil)

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
