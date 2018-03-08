/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This file is largely verbatim from Focus iOS (Blockzilla/Lib/TrackingProtection).
// The preload and postload js files are unmodified from Focus.

import Shared

struct TPPageStats {
    let adCount: Int
    let analyticCount: Int
    let contentCount: Int
    let socialCount: Int

    var total: Int { return adCount + socialCount + analyticCount + contentCount }

    init() {
        adCount = 0
        analyticCount = 0
        contentCount = 0
        socialCount = 0
    }
    
    private init(adCount: Int, analyticCount: Int, contentCount: Int, socialCount: Int) {
        self.adCount = adCount
        self.analyticCount = analyticCount
        self.contentCount = contentCount
        self.socialCount = socialCount
    }

    func create(byAddingListItem listItem: BlocklistName) -> TPPageStats {
        switch listItem {
        case .advertising: return TPPageStats(adCount: adCount + 1, analyticCount: analyticCount, contentCount: contentCount, socialCount: socialCount)
        case .analytics: return TPPageStats(adCount: adCount, analyticCount: analyticCount + 1, contentCount: contentCount, socialCount: socialCount)
        case .content: return TPPageStats(adCount: adCount, analyticCount: analyticCount, contentCount: contentCount + 1, socialCount: socialCount)
        case .social: return TPPageStats(adCount: adCount, analyticCount: analyticCount, contentCount: contentCount, socialCount: socialCount + 1)
        }
    }
}

@available(iOS 11, *)
class TPStatsBlocklistChecker {
    static let shared = TPStatsBlocklistChecker()

    private var blockLists = TPStatsBlocklists()

    func isBlocked(url: URL, isStrictMode: Bool) -> BlocklistName? {
        let enabledLists = BlocklistName.forStrictMode(isOn: isStrictMode)
        return blockLists.urlIsInList(url).flatMap { return enabledLists.contains($0) ? $0 : nil }
    }

}

// The 'unless-domain' and 'if-domain' rules use wildcard expressions, convert this to regex.
func wildcardContentBlockerDomainToRegex(domain: String) -> NSRegularExpression? {
    struct Memo { static var domains =  [String: NSRegularExpression]() }
    if let memoized = Memo.domains[domain] {
        return memoized
    }

    // Convert the domain exceptions into regular expressions.
    var regex = domain + "$"
    if regex.first == "*" {
        regex = "." + regex
    }
    regex = regex.replacingOccurrences(of: ".", with: "\\.")
    do {
        let result = try NSRegularExpression(pattern: regex, options: [])
        Memo.domains[domain] = result
        return result
    } catch {
        assertionFailure("Blocklists: \(error.localizedDescription)")
        return nil
    }
}

@available(iOS 11, *)
fileprivate class TPStatsBlocklists {
    class Rule {
        let regex: NSRegularExpression
        let loadType: LoadType
        let resourceType: ResourceType
        let domainExceptions: [NSRegularExpression]?
        let list: BlocklistName

        init(regex: NSRegularExpression, loadType: LoadType, resourceType: ResourceType, domainExceptions: [NSRegularExpression]?, list: BlocklistName) {
            self.regex = regex
            self.loadType = loadType
            self.resourceType = resourceType
            self.domainExceptions = domainExceptions
            self.list = list
        }
    }

    private var blockRules = [Rule]()

    enum LoadType {
        case all
        case thirdParty
    }

    enum ResourceType {
        case all
        case font
    }

    init() {
        for blockList in BlocklistName.all {
            let list: [[String: AnyObject]]
            do {
                guard let path = Bundle.main.path(forResource: blockList.filename, ofType: "json") else {
                    assertionFailure("Blocklists: bad file path.")
                    return
                }

                let json = try Data(contentsOf: URL(fileURLWithPath: path))
                guard let data = try JSONSerialization.jsonObject(with: json, options: []) as? [[String: AnyObject]] else {
                    assertionFailure("Blocklists: bad JSON cast.")
                    return
                }
                list = data
            } catch {
                assertionFailure("Blocklists: \(error.localizedDescription)")
                return
            }

            for rule in list {
                guard let trigger = rule["trigger"] as? [String: AnyObject],
                    let filter = trigger["url-filter"] as? String,
                    let filterRegex = try? NSRegularExpression(pattern: filter, options: []) else {
                        assertionFailure("Blocklists error: Rule has unexpected format.")
                        continue
                }

                let domainExceptionsRegex = (trigger["unless-domain"] as? [String])?.flatMap { domain in
                        return wildcardContentBlockerDomainToRegex(domain: domain)
                    }

                // Only "third-party" is supported; other types are not used in our block lists.
                let loadTypes = trigger["load-type"] as? [String] ?? []
                let loadType = loadTypes.contains("third-party") ? LoadType.thirdParty : .all

                // Only "font" is supported; other types are not used in our block lists.
                let resourceTypes = trigger["resource-type"] as? [String] ?? []
                let resourceType = resourceTypes.contains("font") ? ResourceType.font : .all

                blockRules.append(Rule(regex: filterRegex, loadType: loadType, resourceType: resourceType, domainExceptions: domainExceptionsRegex, list: blockList))
            }
        }
    }

    func urlIsInList(_ url: URL) -> BlocklistName? {
        let resourceString = url.absoluteString
        let resourceRange = NSRange(location: 0, length: resourceString.count)

        domainSearch: for rule in blockRules {
            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatch(in: resourceString, options: .anchored, range: resourceRange) != nil {
                // Check the domain exceptions. If a domain exception matches, this filter does not apply.
                for domainRegex in (rule.domainExceptions ?? []) {
                    if domainRegex.firstMatch(in: resourceString, options: [], range: resourceRange) != nil {
                        continue domainSearch
                    }
                }

                // Check the whitelist.
                let whitelist = ContentBlockerHelper.whitelistedDomains
                if let baseDomain = url.baseDomain, !whitelist.domainRegex.isEmpty {
                    let range = NSRange(location: 0, length: baseDomain.count)
                    for ignoreDomain in whitelist.domainRegex {
                        if ignoreDomain.firstMatch(in: baseDomain , options: [], range: range) != nil {
                            return nil
                        }
                    }
                }

                return rule.list
            }
        }

        return nil
    }
}
