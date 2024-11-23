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
    case socialCookies = "disconnect-block-cookies-social"

    /// All blocklist files supported at runtime (both for Basic and Strict modes)
    static let allBlocklistFileNames: [String] = {
        return BlocklistFileName.allCases.map { $0.filename } + customBlocklistFileNames
    }()

    var filename: String { return self.rawValue }

    /// Blocklist files compiled for Basic tracking protection mode
    static var basic: [BlocklistFileName] {
        return [
            .advertisingCookies,
            .analyticsCookies,
            .socialCookies,
            .cryptomining,
            .fingerprinting
        ]
    }

    /// Blocklist files compiled for Strict tracking protection mode
    /// If any custom JSON files are included in the bundle with the
    /// required prefix they will also be compiled and applied for Strict.
    static var strict: [BlocklistFileName] {
        return [
            .advertisingURLs,
            .analyticsURLs,
            .socialURLs,
            .cryptomining,
            .fingerprinting
        ]
    }

    static func listsForMode(strict: Bool) -> [String] {
        return strict ? (Self.strict.map { $0.filename } + customBlocklistFileNames) : Self.basic.map { $0.filename }
    }

    static let customBlocklistJSONFilePrefix = "fxcb-"
    static let customBlocklistFileNames: [String] = {
        var filenames: [String] = []
        // Search the bundle for resources that match content blocking prefix + JSON type.
        // This allows custom block lists to be more easily tested and loaded within the
        // iOS client. Any custom lists can be bundled as json with the `fxcb-` prefix
        // and they will be loaded alongside our standard Disconnect files.
        if let resourceDir = Bundle.main.resourcePath,
           let contents = try? FileManager.default.contentsOfDirectory(atPath: resourceDir) {
            let filePrefix = customBlocklistJSONFilePrefix
            contents.forEach {
                guard $0.hasPrefix(filePrefix) && $0.hasSuffix("json") else { return }
                filenames.append($0)
            }
        }
        return filenames
    }()
}

enum BlockerStatus: String {
    case disabled
    case noBlockedURLs // When TP is enabled but nothing is being blocked
    case safelisted
    case blocking
}

struct NoImageModeDefaults {
    static let Script =
    """
    [{"trigger":{"url-filter":".*","resource-type":["image"]},"action":{"type":"block"}}]
    """
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
        self.logger = logger

        // Compile No Image Mode script
        compileNoImageModeScript()

        // Read the safelist at startup
        if let list = readSafelistFile() {
            safelistedDomains.domainSet = Set(list)
        }

        // Startup tracking stats checker
        TPStatsBlocklistChecker.shared.startup()

        // General list startup: remove old content-block lists (if needed) and compile latest lists
        logger.log("ContentBlocker startup...", level: .info, category: .adblock)
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
        rules: [String],
        completion: (() -> Void)?
    ) {
        removeTrackingProtection(forTab: tab)

        guard isEnabled else {
            completion?()
            return
        }

        let group = DispatchGroup()

        for list in rules {
            group.enter()
            ruleStore?.lookUpContentRuleList(forIdentifier: list) { rule, error in
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

    private func compileNoImageModeScript() {
        let logger = self.logger
        let blockImages = NoImageModeDefaults.Script
        ruleStore?.compileContentRuleList(
            forIdentifier: NoImageModeDefaults.ScriptName,
            encodedContentRuleList: blockImages) { rule, error in
                if let error {
                    logger.log("No Image script failed compilation: \(error))", level: .warning, category: .adblock)
                    assertionFailure()
                    return
                }

                guard rule != nil else {
                    logger.log("Nil rule set for NoImageMode.", level: .warning, category: .adblock)
                    assertionFailure()
                    return
                }

                self.blockImagesRule = rule
        }
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
        let logger = self.logger
        DispatchQueue.global().async {
            var source = ""
            do {
                let jsonSuffix = ".json"
                let suffixLength = jsonSuffix.count
                // Trim off .json suffix if needed, we only want the raw file name
                let fileTrimmed = file.hasSuffix(jsonSuffix) ? String(file.dropLast(suffixLength)) : file

                if fileTrimmed.hasPrefix(BlocklistFileName.customBlocklistJSONFilePrefix) {
                    if let path = Bundle.main.path(forResource: fileTrimmed, ofType: "json") {
                        source = try String(contentsOfFile: path, encoding: .utf8)
                    }
                } else {
                    let json = try RemoteDataType.contentBlockingLists.loadLocalSettingsFileAsJSON(fileName: fileTrimmed)
                    source = String(data: json, encoding: .utf8) ?? ""
                }
            } catch let error {
                logger.log("Error loading content-blocking JSON: \(error)", level: .warning, category: .adblock)
                assertionFailure("Error loading JSON from bundle.")
            }

            DispatchQueue.main.async {
                completion(source)
            }
        }
    }

    func removeAllRulesInStore(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        let logger = self.logger
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
            logger.log("Removed \(available.count) lists from rule store.", level: .info, category: .adblock)
            dispatchGroup.notify(queue: DispatchQueue.main) {
                completion()
            }
        }
    }

    private func calculateHash(for fileData: Data) -> String? {
        let hash = SHA256.hash(data: fileData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func hasBlockerFileChanged() -> Bool {
        let blocklists = BlocklistFileName.allBlocklistFileNames
        let defaults = UserDefaults.standard
        var hasChanged = false

        let lists = RemoteDataType.contentBlockingLists
        for list in blocklists {
            guard let data = try? lists.loadLocalSettingsFileAsJSON(fileName: list) else { continue }
            guard let newHash = calculateHash(for: data) else { continue }

            let oldHash = defaults.string(forKey: list)
            if oldHash != newHash {
                defaults.set(newHash, forKey: list)
                hasChanged = true
            }
        }

        return hasChanged
    }

    // If any blocker files have a newer hash than the hash saved in defaults,
    // remove all the content blockers and reload them.
    func removeOldListsByHashFromStore(completion: @escaping () -> Void) {
        if hasBlockerFileChanged() {
            logger.log("Did remove stale content blocking cache (update required)", level: .info, category: .adblock)
            removeAllRulesInStore {
                completion()
            }
        } else {
            logger.log("Cached content blocking lists Ok.", level: .info, category: .adblock)
            completion()
        }
    }

    func removeOldListsByNameFromStore(completion: @escaping () -> Void) {
        var noMatchingIdentifierFoundForRule = false

        let logger = self.logger
        ruleStore?.getAvailableContentRuleListIdentifiers { available in
            guard let available else {
                completion()
                return
            }

            let blocklists = BlocklistFileName.allBlocklistFileNames
            // If any file from the list on disk is not installed, remove all the rules and re-install them
            for listOnDisk in blocklists where !available.contains(where: { $0 == listOnDisk }) {
                noMatchingIdentifierFoundForRule = true
                break
            }

            if !noMatchingIdentifierFoundForRule {
                logger.log("All lists are installed.", level: .info, category: .adblock)
                completion()
            } else {
                logger.log("Some lists not installed, will re-install all.", level: .info, category: .adblock)
                self.removeAllRulesInStore {
                    completion()
                }
            }
        }
    }

    func compileListsNotInStore(completion: @escaping () -> Void) {
        // Compile the content blocking (in WebKit's required JSON format) for use with WKWebView
        logger.log("Compiling any lists not already in rule store...", level: .info, category: .adblock)
        let blocklists = BlocklistFileName.allBlocklistFileNames
        let dispatchGroup = DispatchGroup()
        let totalListCount = blocklists.count
        var listsCompiledCount = 0
        var errorCount = 0
        blocklists.forEach { filename in
            dispatchGroup.enter()
            ruleStore?.lookUpContentRuleList(forIdentifier: filename) { [weak self] contentRuleList, error in
                // If the rule was found, we can exit immediately
                if contentRuleList != nil {
                    dispatchGroup.leave()
                    return
                }

                self?.logger.log("Will compile list: \(filename)", level: .info, category: .adblock)
                self?.loadJsonFromBundle(forResource: filename) { jsonString in
                    var str = jsonString

                    // Here we find the closing array bracket in the JSON string
                    // and append our safelist as a rule to the end of the JSON.
                    guard let self, let range = str.range(of: "]", options: String.CompareOptions.backwards) else {
                        dispatchGroup.leave()
                        return
                    }
                    str = str.replacingCharacters(in: range, with: self.safelistAsJSON() + "]")
                    self.ruleStore?.compileContentRuleList(
                        forIdentifier: filename,
                        encodedContentRuleList: str
                    ) { rule, error in
                        listsCompiledCount += 1
                        errorCount += (error == nil ? 0 : 1)
                        self.compileContentRuleListCompletion(dispatchGroup: dispatchGroup, rule: rule, error: error)
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.logger.log("Compiled \(listsCompiledCount) of \(totalListCount) lists checked. \(errorCount) errors.",
                             level: .info,
                             category: .adblock)
            completion()
        }
    }

    private func compileContentRuleListCompletion(dispatchGroup: DispatchGroup,
                                                  rule: WKContentRuleList?,
                                                  error: (any Error)?) {
        defer {
            dispatchGroup.leave()
        }
        if let error {
            logger.log("Content blocker compilation failed: \(error)", level: .warning, category: .adblock)
            assertionFailure()
            return
        }
        guard rule != nil else {
            logger.log("Nil rule set for BlockList.", level: .warning, category: .adblock)
            assertionFailure()
            return
        }
    }
}
