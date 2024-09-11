// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Shared
import Common
import CryptoKit

enum BlocklistCategory: CaseIterable {
    case advertising
    case analytics
    case social
    case cryptomining
    case fingerprinting

    static func fromFile(_ file: BlocklistFileName) -> BlocklistCategory {
        switch file {
        case .advertisingURLs, .advertisingCookies:
            return .advertising
        case .analyticsURLs, .analyticsCookies:
            return .analytics
        case .socialURLs, .socialCookies:
            return .social
        case .cryptomining:
            return .cryptomining
        case .fingerprinting:
            return .fingerprinting
        }
    }
}

enum BlocklistFileName: String, CaseIterable {
    case advertisingURLs = "disconnect-block-advertising"
    case analyticsURLs = "disconnect-block-analytics"
    case socialURLs = "disconnect-block-social"

    case cryptomining = "disconnect-block-cryptomining"
    case fingerprinting = "disconnect-block-fingerprinting"

    case advertisingCookies = "disconnect-block-cookies-advertising"
    case analyticsCookies = "disconnect-block-cookies-analytics"
    // case contentCookies = "disconnect-block-cookies-content"
    case socialCookies = "disconnect-block-cookies-social"

    var filename: String { return self.rawValue }

    static var basic: [BlocklistFileName] {
        return [
            .advertisingCookies,
            .analyticsCookies,
            .socialCookies,
            .cryptomining,
            .fingerprinting
        ]
    }
    static var strict: [BlocklistFileName] {
        return [
            .advertisingURLs,
            .analyticsURLs,
            .socialURLs,
            cryptomining,
            fingerprinting
        ]
    }

    static func listsForMode(strict: Bool) -> [BlocklistFileName] {
        return strict ? BlocklistFileName.strict : BlocklistFileName.basic
    }
}

enum BlockerStatus: String {
    case disabled
    case noBlockedURLs // When TP is enabled but nothing is being blocked
    case safelisted
    case blocking
}

struct NoImageModeDefaults {
    static let Script = "[{'trigger':{'url-filter':'.*','resource-type':['image']},'action':{'type':'block'}}]"
        .replacingOccurrences(of: "'", with: "\"")
    static let ScriptName = "images"
}

class ContentBlocker {
    var safelistedDomains = SafelistedDomains()
    let ruleStore = WKContentRuleListStore.default()
    var blockImagesRule: WKContentRuleList?
    var setupCompleted = false
    let logger: Logger

    static let shared = ContentBlocker()

    private init(logger: Logger = DefaultLogger.shared) {
        let blockImages = NoImageModeDefaults.Script
        self.logger = logger
        ruleStore?.compileContentRuleList(
            forIdentifier: NoImageModeDefaults.ScriptName,
            encodedContentRuleList: blockImages) { rule, error in
                guard error == nil else {
                    logger.log(
                        "We errored with error: \(String(describing: error))",
                        level: .warning,
                        category: .webview
                    )
                    assert(error == nil)
                    return
                }

                guard rule != nil else {
                    logger.log(
                        "We came across a nil rule set for NoImageMode at this point.",
                        level: .warning,
                        category: .webview
                    )
                    assert(rule != nil)
                    return
                }

                self.blockImagesRule = rule
        }

        // Read the safelist at startup
        if let list = readSafelistFile() {
            safelistedDomains.domainSet = Set(list)
        }

        TPStatsBlocklistChecker.shared.startup()

        removeOldListsByHashFromStore { [weak self] in
            self?.removeOldListsByNameFromStore {
                self?.compileListsNotInStore {
                    self?.setupCompleted = true
                    NotificationCenter.default.post(name: .contentBlockerTabSetupRequired, object: nil)
                }
            }
        }
    }

    func prefsChanged() {
        // This class func needs to notify all the active instances of ContentBlocker to update.
        NotificationCenter.default.post(name: .contentBlockerTabSetupRequired, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Function to install or remove TP for a tab
    func setupTrackingProtection(
        forTab tab: ContentBlockerTab,
        isEnabled: Bool,
        rules: [BlocklistFileName],
        completion: (() -> Void)?
    ) {
        removeTrackingProtection(forTab: tab)

        guard isEnabled else {
            completion?()
            return
        }

        let group = DispatchGroup()

        for list in rules {
            let name = list.filename
            group.enter()
            ruleStore?.lookUpContentRuleList(forIdentifier: name) { rule, error in
                if let rule = rule {
                    self.add(contentRuleList: rule, toTab: tab)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    private func removeTrackingProtection(forTab tab: ContentBlockerTab) {
        tab.currentWebView()?.configuration.userContentController.removeAllContentRuleLists()

        // Add back the block images rule (if needed) after having removed all rules.
        if let rule = blockImagesRule, tab.imageContentBlockingEnabled() {
            add(contentRuleList: rule, toTab: tab)
        }
    }

    private func add(contentRuleList: WKContentRuleList, toTab tab: ContentBlockerTab) {
        tab.currentWebView()?.configuration.userContentController.add(contentRuleList)
    }

    func noImageMode(enabled: Bool, forTab tab: ContentBlockerTab) {
        guard let rule = blockImagesRule else { return }

        if enabled {
            add(contentRuleList: rule, toTab: tab)
        } else {
            tab.currentWebView()?.configuration.userContentController.remove(rule)
        }

        // Async required here to ensure remove() call is processed.
        DispatchQueue.main.async { [weak tab] in
            tab?.currentWebView()?
                .evaluateJavascriptInDefaultContentWorld("window.__firefox__.NoImageMode.setEnabled(\(enabled))")
        }
    }
}

// MARK: Initialization code
// The rule store can compile JSON rule files into a private format which is cached on disk.
// On app boot, we need to check if the ruleStore's data is out-of-date, or if the names of the rule files
// no longer match. Finally, any JSON rule files that aren't in the ruleStore need to be compiled and stored in the
// ruleStore.
extension ContentBlocker {
    private func loadJsonFromBundle(forResource file: String, completion: @escaping (_ jsonString: String) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let path = Bundle.main.path(forResource: file, ofType: "json"),
                  let source = try? String(contentsOfFile: path, encoding: .utf8)
            else {
                self?.logger.log("Error unwrapping the resource contents", level: .warning, category: .webview)
                assertionFailure("Error unwrapping the resource contents")
                return
            }

            DispatchQueue.main.async {
                completion(source)
            }
        }
    }

    func removeAllRulesInStore(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        ruleStore?.getAvailableContentRuleListIdentifiers { [weak self] available in
            guard let available = available else {
                completion()
                return
            }
            for filename in available {
                dispatchGroup.enter()
                self?.ruleStore?.removeContentRuleList(forIdentifier: filename) { _ in
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main) {
                completion()
            }
        }
    }

    private func calculateHash(forFileAtPath path: String) -> String? {
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func hasBlockerFileChanged() -> Bool {
        let blocklists = BlocklistFileName.allCases
        let defaults = UserDefaults.standard
        var hasChanged = false

        for list in blocklists {
            guard let path = Bundle.main.path(forResource: list.filename, ofType: "json"),
                  let newHash = calculateHash(forFileAtPath: path) else { continue }

            let oldHash = defaults.string(forKey: list.filename)
            if oldHash != newHash {
                defaults.set(newHash, forKey: list.filename)
                hasChanged = true
            }
        }

        return hasChanged
    }

    // If any blocker files have a newer hash than the hash saved in defaults,
    // remove all the content blockers and reload them.
    func removeOldListsByHashFromStore(completion: @escaping () -> Void) {
        if hasBlockerFileChanged() {
            removeAllRulesInStore {
                completion()
            }
        } else {
            completion()
        }
    }

    func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        ruleStore?.getAvailableContentRuleListIdentifiers { available in
            guard let available = available else {
                completion()
                return
            }

            let blocklists = BlocklistFileName.allCases.map { $0.filename }
            // If any file from the list on disk is not installed, remove all the rules and re-install them
            for listOnDisk in blocklists where !available.contains(where: { $0 == listOnDisk }) {
                noMatchingIdentifierFoundForRule = true
                break
            }

            if !noMatchingIdentifierFoundForRule {
                completion()
                return
            }

            self.removeAllRulesInStore {
                completion()
            }
        }
    }

    func compileListsNotInStore(completion: @escaping () -> Void) {
        let blocklists = BlocklistFileName.allCases.map { $0.filename }
        let dispatchGroup = DispatchGroup()
        blocklists.forEach { filename in
            dispatchGroup.enter()
            ruleStore?.lookUpContentRuleList(forIdentifier: filename) { [weak self] contentRuleList, error in
                if contentRuleList != nil {
                    dispatchGroup.leave()
                    return
                }
                self?.loadJsonFromBundle(forResource: filename) { jsonString in
                    var str = jsonString
                    guard let self,
                          let range = str.range(of: "]", options: String.CompareOptions.backwards)
                    else {
                        dispatchGroup.leave()
                        return
                    }
                    str = str.replacingCharacters(in: range, with: self.safelistAsJSON() + "]")
                    self.ruleStore?.compileContentRuleList(
                        forIdentifier: filename,
                        encodedContentRuleList: str
                    ) { rule, error in
                        self.compileContentRuleListCompletion(dispatchGroup: dispatchGroup, rule: rule, error: error)
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }

    private func compileContentRuleListCompletion(dispatchGroup: DispatchGroup,
                                                  rule: WKContentRuleList?,
                                                  error: (any Error)?) {
        defer {
            dispatchGroup.leave()
        }
        guard error == nil else {
            self.logger.log(
                "Content blocker errored with: \(String(describing: error))",
                level: .warning,
                category: .webview
            )
            assert(error == nil)
            return
        }
        guard rule != nil else {
            self.logger.log(
                "We came across a nil rule set for BlockList.",
                level: .warning,
                category: .webview
            )
            assert(rule != nil)
            return
        }
    }
}
