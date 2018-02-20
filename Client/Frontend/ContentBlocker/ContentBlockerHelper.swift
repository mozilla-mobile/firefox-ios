/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Shared
import Deferred

enum BlockList: String {
    case advertising = "disconnect-advertising"
    case analytics = "disconnect-analytics"
    case content = "disconnect-content"
    case social = "disconnect-social"

    var fileName: String { return self.rawValue }

    static var all: [BlockList] { return [.advertising, .analytics, .content, .social] }
    static var basic: [BlockList] { return [.advertising, .analytics, .social] }
    static var strict: [BlockList] { return [.content] }

    static func forStrictMode(isOn: Bool) -> [BlockList] {
        return BlockList.basic + (isOn ? BlockList.strict : [])
    }
}

struct TPDefaults {
    static let PrefKeyStrength = "prefkey.trackingprotection.strength"
    static let PrefKeyNormalBrowsingEnabled = "prefkey.trackingprotection.normalbrowsing"
    static let PrefKeyPrivateBrowsingEnabled = "prefkey.trackingprotection.privatebrowsing"
    static let TPNormalBrowsingDefault = false
    static let TPPrivateBrowsingDefault = true
}

struct NoImageModeDefaults {
    static let Script = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]"
    static let ScriptName = "images"
}

@available(iOS 11.0, *)
class ContentBlockerHelper {

    fileprivate let ruleStore: WKContentRuleListStore = WKContentRuleListStore.default()
    fileprivate weak var tab: Tab?
    fileprivate var userPrefs: Prefs?
    fileprivate(set) var stats = TrackingInformation()

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

    fileprivate var isEnabledInNormalBrowsing: Bool {
        return userPrefs?.boolForKey(TPDefaults.PrefKeyNormalBrowsingEnabled) ?? TPDefaults.TPNormalBrowsingDefault
    }

    fileprivate var isEnabledInPrivateBrowsing: Bool {
        return userPrefs?.boolForKey(TPDefaults.PrefKeyPrivateBrowsingEnabled) ?? TPDefaults.TPPrivateBrowsingDefault
    }

    fileprivate var blockingStrengthPref: BlockingStrength {
        return userPrefs?.stringForKey(TPDefaults.PrefKeyStrength).flatMap(BlockingStrength.init) ?? .basic
    }

    static fileprivate var blockImagesRule: WKContentRuleList?
    static fileprivate var whitelistedDomains = [String]()
    static private var heavyInitHasRunOnce = false

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

        ContentBlockerHelper.heavyInitHasRunOnce = true
        migrateLegacyUserPrefs()

        // Read the whitelist at startup
        let text = readWhitelistFile()
        if let text = text, !text.isEmpty {
            ContentBlockerHelper.whitelistedDomains = text.components(separatedBy: .newlines)
        }

        removeOldListsByDateFromStore() {
            self.removeOldListsByNameFromStore() {
                self.compileListsNotInStore(completion: {})
            }
        }

        let blockImages = NoImageModeDefaults.Script.escapeJSON()
        ruleStore.compileContentRuleList(forIdentifier: NoImageModeDefaults.ScriptName, encodedContentRuleList: blockImages) { rule, error in
            assert(rule != nil && error == nil)
            ContentBlockerHelper.blockImagesRule = rule
        }
    }

    func setupForWebView() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateTab), name: .ContentBlockerUpdateNeeded, object: nil)
        addActiveRulesToTab()
    }

    static func prefsChanged() {
        NotificationCenter.default.post(name: .ContentBlockerUpdateNeeded, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func updateTab() {
        addActiveRulesToTab()
    }

    // If a user had set a pref for Tracking Protection outside of the previous defaults then make sure to honor those settings
    fileprivate func migrateLegacyUserPrefs() {
        // If a user had set PrefEnabledState to ON this means that TP was on in normal browsing
        // if a user had set PrefEnabledState to OFF this means that TP was off in both normal and private browsing
        if let legacyPref = userPrefs?.stringForKey("prefkey.trackingprotection.enabled")  {
            if legacyPref == "on" {
                userPrefs?.setBool(true, forKey: TPDefaults.PrefKeyNormalBrowsingEnabled)
            } else if legacyPref == "off" {
                userPrefs?.setBool(false, forKey: TPDefaults.PrefKeyNormalBrowsingEnabled)
                userPrefs?.setBool(false, forKey: TPDefaults.PrefKeyPrivateBrowsingEnabled)
            }
            // We only need to do this once. We can wipe the old pref
            userPrefs?.removeObjectForKey("prefkey.trackingprotection.enabled")
        }
    }

    fileprivate func addActiveRulesToTab() {
        removeTrackingProtection()

        guard isEnabled else {
            return
        }

        let rules = BlockList.forStrictMode(isOn: blockingStrengthPref == .strict)
        for list in rules {
            let name = list.fileName
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

    fileprivate func removeTrackingProtection() {
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
            self.tab?.webView?.evaluateJavaScript("window.__firefox__.NoImageMode.setEnabled(\(enabled))")
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
                let source = try? String(contentsOfFile: path, encoding: .utf8) else {
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
        let blocklists = BlockList.all
        return blocklists.reduce(Timestamp(0)) { result, list in
            guard let path = Bundle.main.path(forResource: list.fileName, ofType: "json") else { return result }
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

    fileprivate func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        ruleStore.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }

            let blocklists = BlockList.all.map { $0.fileName }
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

    fileprivate func compileListsNotInStore(completion: @escaping () -> Void) {
        let blocklists = BlockList.all.map { $0.fileName}
        let deferreds: [Deferred<Void>] = blocklists.map { filename in
            let result = Deferred<Void>()
            ruleStore.lookUpContentRuleList(forIdentifier: filename) { contentRuleList, error in
                if contentRuleList != nil {
                    result.fill()
                    return
                }
                self.loadJsonFromBundle(forResource: filename) { jsonString in
                    var str = jsonString
                    str.insert(contentsOf: self.whitelistJSON(), at: str.index(str.endIndex, offsetBy: -1) )
                    self.ruleStore.compileContentRuleList(forIdentifier: filename, encodedContentRuleList: str) { _, _ in
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

// MARK: Whitelisting support
@available(iOS 11.0, *)
extension ContentBlockerHelper {

    static func whitelistFileURL() -> URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Sentry.shared.send(message: "Failed to get doc dir for whitelist file.")
            return nil
        }
        return dir.appendingPathComponent("whitelist")
    }

    fileprivate func whitelistJSON() -> String {
        if ContentBlockerHelper.whitelistedDomains.isEmpty {
            return ""
        }
        // Note that * is added to the front of domains, so foo.com becomes *foo.com
        let list = "'*" + ContentBlockerHelper.whitelistedDomains.joined(separator: "','*") + "'"
        return ", {'action': { 'type': 'ignore-previous-rules' }, 'trigger': { 'url-filter': '.*', 'unless-domain': [\(list)] }".escapeJSON()
    }

    func whitelist(enable: Bool, forDomain domain: String, completion: (() -> Void)? = nil) {
        if enable {
            ContentBlockerHelper.whitelistedDomains.append(domain)
        } else {
            ContentBlockerHelper.whitelistedDomains = ContentBlockerHelper.whitelistedDomains.filter { $0 != domain }
        }

        BlockListChecker.shared.whitelistedDomains = ContentBlockerHelper.whitelistedDomains

        removeAllRulesInStore {
            self.compileListsNotInStore {
                NotificationCenter.default.post(name: .ContentBlockerUpdateNeeded, object: nil)
                completion?()
            }
        }

        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return }
        let list = ContentBlockerHelper.whitelistedDomains.joined(separator: "\n")
        do {
            try list.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            Sentry.shared.send(message: "Failed to save whitelist file")
        }
    }

    func isURLWhitelisted(url: URL) -> Bool {
        // TODO: Not done
        return false
    }

    fileprivate func readWhitelistFile() -> String? {
        guard let fileURL = ContentBlockerHelper.whitelistFileURL() else { return nil }
        let text = try? String(contentsOf: fileURL, encoding: .utf8)
        return text
    }

}

@available(iOS 11.0, *)
enum BlockingStrength: String {
    case basic
    case strict

    static let allOptions: [BlockingStrength] = [.basic, .strict]
}

@available(iOS 11, *)
extension ContentBlockerHelper : TabContentScript {
    class func name() -> String {
        return "TrackingProtectionStats"
    }

    func scriptMessageHandlerName() -> String? {
        return "trackingProtectionStats"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard isEnabled, let body = message.body as? [String: String], let urlString = body["url"] else {
            return
        }

        guard var components = URLComponents(string: urlString) else { return }
        components.scheme = "http"
        guard let url = components.url else { return }

        if let listItem = BlockListChecker.shared.isBlocked(url: url, isStrictMode: blockingStrengthPref == .strict) {
            stats = stats.create(byAddingListItem: listItem)
        }
    }

}
