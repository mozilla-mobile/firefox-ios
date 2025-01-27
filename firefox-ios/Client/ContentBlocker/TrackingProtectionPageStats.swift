// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

struct TPPageStats {
    var domains: [BlocklistCategory: Set<String>]

    var total: Int {
        var total = 0
        domains.forEach { total += $0.1.count }
        return total
    }

    init() {
        domains = [BlocklistCategory: Set<String>]()
    }

    private init(
        domains: [BlocklistCategory: Set<String>],
        blocklistName: BlocklistCategory,
        host: String
    ) {
        self.domains = domains
        if self.domains[blocklistName] == nil {
            self.domains[blocklistName] = Set<String>()
        }
       self.domains[blocklistName]?.insert(host)
    }

    func create(
        matchingBlocklist blocklistName: BlocklistCategory,
        host: String
    ) -> TPPageStats {
        return TPPageStats(domains: domains, blocklistName: blocklistName, host: host)
    }

    func getTrackersBlockedForCategory(_ category: BlocklistCategory) -> Int {
        return domains[category]?.count ?? 0
    }
}

class TPStatsBlocklistChecker {
    static let shared = TPStatsBlocklistChecker()

    // Initialized async, is non-nil when ready to be used.
    private var blockLists: TPStatsBlocklists?

    func isBlocked(
        url: URL,
        mainDocumentURL: URL,
        completionHandler: @escaping (BlocklistCategory?) -> Void
    ) {
        guard let blockLists = blockLists,
              let host = url.host,
              !host.isEmpty
        else {
            // TP Stats init isn't complete yet
            completionHandler(nil)
            return
        }

        guard let domain = url.baseDomain,
              let docDomain = mainDocumentURL.baseDomain,
              domain != docDomain
        else {
            completionHandler(nil)
            return
        }

        // Make a copy on the main thread
        let safelistRegex = ContentBlocker.shared.safelistedDomains.domainRegex

        DispatchQueue.global().async {
            // Return true in the Deferred if the domain could potentially be blocked
            completionHandler(
                blockLists.urlIsInList(
                    url,
                    mainDocumentURL: mainDocumentURL,
                    safelistedDomains: safelistRegex
                )
            )
        }
    }

    func startup() {
        DispatchQueue.global().async {
            let parser = TPStatsBlocklists()
            parser.load()
            DispatchQueue.main.async {
                self.blockLists = parser
            }
        }
    }
}

// The 'unless-domain' and 'if-domain' rules use wildcard expressions, convert this to regex.
func wildcardContentBlockerDomainToRegex(domain: String) -> String? {
    struct Memo { static var domains = [String: String]() }

    if let memoized = Memo.domains[domain] {
        return memoized
    }

    // Convert the domain exceptions into regular expressions.
    var regex = domain + "$"
    if regex.first == "*" {
        regex = "." + regex
    }
    regex = regex.replacingOccurrences(of: ".", with: "\\.")

    Memo.domains[domain] = regex
    return regex
}

class TPStatsBlocklists {
    class Rule {
        let regex: String
        let loadType: LoadType
        let resourceType: ResourceType
        let domainExceptions: [String]?
        let list: BlocklistCategory

        init(
            regex: String,
            loadType: LoadType,
            resourceType: ResourceType,
            domainExceptions: [String]?,
            list: BlocklistCategory
        ) {
            self.regex = regex
            self.loadType = loadType
            self.resourceType = resourceType
            self.domainExceptions = domainExceptions
            self.list = list
        }
    }

    private let logger: Logger
    private var blockRules = [String: [Rule]]()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    enum LoadType {
        case all
        case thirdParty
    }

    enum ResourceType {
        case all
        case font
    }

    func load() {
        // All rules have this prefix on the domain to match.
        let standardPrefix = "^https?://([^/]+\\.)?"

        // Use the strict list of files, as it is the complete list of rules,
        // keeping in mind the stats can't distinguish block vs cookie-block,
        // only that an url did or didn't match.
        for blockListFile in [
            BlocklistFileName.advertisingURLs,
            BlocklistFileName.analyticsURLs,
            BlocklistFileName.socialURLs,
            BlocklistFileName.cryptomining,
            BlocklistFileName.fingerprinting,
            ] {
            let list: [[String: AnyObject]]
            do {
                let settingsLists = RemoteDataType.contentBlockingLists
                guard let json = try? settingsLists.loadLocalSettingsFileAsJSON(fileName: blockListFile.filename) else {
                    logger.log("Blocklists: could not load blocklist JSON file.", level: .warning, category: .webview)
                    assertionFailure("Blocklists: could not load file.")
                    continue
                }
                guard let data = try JSONSerialization.jsonObject(
                    with: json,
                    options: []
                ) as? [[String: AnyObject]] else {
                    logger.log(
                        "Blocklists: bad JSON cast.",
                        level: .warning,
                        category: .webview
                    )
                    assertionFailure("Blocklists: bad JSON cast.")
                    return
                }
                list = data
            } catch {
                logger.log(
                    "Blocklists: \(error.localizedDescription)",
                    level: .warning,
                    category: .webview
                )
                assertionFailure("Blocklists: \(error.localizedDescription)")
                return
            }

            for rule in list {
                guard let trigger = rule["trigger"] as? [String: AnyObject],
                      let filter = trigger["url-filter"] as? String
                else {
                    logger.log(
                        "Blocklists error: Rule has unexpected format.",
                        level: .warning,
                        category: .webview
                    )
                    assertionFailure("Blocklists error: Rule has unexpected format.")
                    continue
                }

                guard let loc = filter.range(of: standardPrefix) else {
                    logger.log(
                        "url-filter code needs updating for new list format",
                        level: .warning,
                        category: .webview
                    )
                    assertionFailure("url-filter code needs updating for new list format")
                    return
                }

                let baseDomain = String(filter[loc.upperBound...]).replacingOccurrences(of: "\\.", with: ".")
                if baseDomain.isEmpty {
                    logger.log("baseDomain is unexpectedly empty!", level: .warning, category: .webview)
                    assert(!baseDomain.isEmpty)
                }

                // Sanity check for the lists.
                ["*", "?", "+"].forEach { x in
                    // This will only happen on debug
                    if baseDomain.contains(x) {
                        logger.log(
                            "Unexpectedly found a wildcard in baseDomain - wildcard: \(x)",
                            level: .warning,
                            category: .webview
                        )
                        assert(!baseDomain.contains(x), "No wildcards allowed in baseDomain")
                    }
                }

                let domainExceptionsRegex = (trigger["unless-domain"] as? [String])?.compactMap { domain in
                    return wildcardContentBlockerDomainToRegex(domain: domain)
                }

                // Only "third-party" is supported; other types are not used in our block lists.
                let loadTypes = trigger["load-type"] as? [String] ?? []
                let loadType = loadTypes.contains("third-party") ? LoadType.thirdParty : .all

                // Only "font" is supported; other types are not used in our block lists.
                let resourceTypes = trigger["resource-type"] as? [String] ?? []
                let resourceType = resourceTypes.contains("font") ? ResourceType.font : .all

                let category = BlocklistCategory.fromFile(blockListFile)
                let rule = Rule(
                    regex: filter,
                    loadType: loadType,
                    resourceType: resourceType,
                    domainExceptions: domainExceptionsRegex,
                    list: category
                )
                blockRules[baseDomain] = (blockRules[baseDomain] ?? []) + [rule]
            }
        }
    }

    func urlIsInList(_ url: URL, mainDocumentURL: URL, safelistedDomains: [String]) -> BlocklistCategory? {
        let resourceString = url.absoluteString

        guard let firstPartyDomain = mainDocumentURL.baseDomain,
              let baseDomain = url.baseDomain,
              let rules = blockRules[baseDomain]
        else { return nil }

        // First, test the top-level filters to see if this URL might be blocked.
        domainSearch: for rule in rules where resourceString.range(
            of: rule.regex,
            options: .regularExpression) != nil {
            // Check the domain exceptions. If a domain exception matches, this filter does not apply.
            for domainRegex in (rule.domainExceptions ?? []) where firstPartyDomain.range(
                of: domainRegex,
                options: .regularExpression) != nil {
                continue domainSearch
            }

            // Check the safelist.
            if let baseDomain = url.baseDomain, !safelistedDomains.isEmpty {
                for ignoreDomain in safelistedDomains where baseDomain.range(
                    of: ignoreDomain,
                    options: .regularExpression) != nil {
                    return nil
                }
            }

            return rule.list
        }

        return nil
    }
}
