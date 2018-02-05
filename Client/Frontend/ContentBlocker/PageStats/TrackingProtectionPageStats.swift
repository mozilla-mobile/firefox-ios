/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This file is largely verbatim from Focus iOS (Blockzilla/Lib/TrackingProtection).
// The preload and postload js files are unmodified from Focus.

import Shared

struct TrackingInformation {
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

    func create(byAddingListItem listItem: BlockList) -> TrackingInformation {
        switch listItem {
        case .advertising: return TrackingInformation(adCount: adCount + 1, analyticCount: analyticCount, contentCount: contentCount, socialCount: socialCount)
        case .analytics: return TrackingInformation(adCount: adCount, analyticCount: analyticCount + 1, contentCount: contentCount, socialCount: socialCount)
        case .content: return TrackingInformation(adCount: adCount, analyticCount: analyticCount, contentCount: contentCount + 1, socialCount: socialCount)
        case .social: return TrackingInformation(adCount: adCount, analyticCount: analyticCount, contentCount: contentCount, socialCount: socialCount + 1)
        }
    }
}

@available(iOS 11, *)
class BlockListChecker {
    static let shared = BlockListChecker()
    var whitelistedDomains: [String] {
        didSet {
            whitelistNeedsUpdate = true
        }
    }

    private var whitelistNeedsUpdate = true
    private var blockLists = BlockLists()
    private init() {
        whitelistedDomains = []
    }

    func isBlocked(url: URL, isStrictMode: Bool) -> BlockList? {
        if whitelistNeedsUpdate {
            whitelistNeedsUpdate = false
            blockLists.updateWhitelistedDomains(whitelistedDomains)
        }
        let enabledLists = BlockList.forStrictMode(isOn: isStrictMode)
        return blockLists.urlIsInList(url).flatMap { return enabledLists.contains($0) ? $0 : nil }
    }

}

@available(iOS 11, *)
fileprivate class BlockLists {
    class Rule {
        let regex: NSRegularExpression
        let loadType: LoadType
        let resourceType: ResourceType
        let domainExceptions: [NSRegularExpression]?
        let list: BlockList

        init(regex: NSRegularExpression, loadType: LoadType, resourceType: ResourceType, domainExceptions: [NSRegularExpression]?, list: BlockList) {
            self.regex = regex
            self.loadType = loadType
            self.resourceType = resourceType
            self.domainExceptions = domainExceptions
            self.list = list
        }
    }

    fileprivate var blockRules = [Rule]()

    enum LoadType {
        case all
        case thirdParty
    }

    enum ResourceType {
        case all
        case font
    }

    func updateWhitelistedDomains(_ domains: [String]) {
        whitelisted = domains.flatMap { wildcardDomainToRegex(domain: "*" + $0) }
    }

    private var whitelisted = [NSRegularExpression]()

    init() {
        for blockList in BlockList.all {
            let list: [[String: AnyObject]]
            do {
                guard let path = Bundle.main.path(forResource: blockList.fileName, ofType: "json") else {
                    assertionFailure("BlockLists: bad file path.")
                    return
                }

                let json = try Data(contentsOf: URL(fileURLWithPath: path))
                guard let data = try JSONSerialization.jsonObject(with: json, options: []) as? [[String: AnyObject]] else {
                    assertionFailure("BlockLists: bad JSON cast.")
                    return
                }
                list = data
            } catch {
                assertionFailure("BlockLists: \(error.localizedDescription)")
                return
            }

            for rule in list {
                guard let trigger = rule["trigger"] as? [String: AnyObject],
                    let filter = trigger["url-filter"] as? String,
                    let filterRegex = try? NSRegularExpression(pattern: filter, options: []) else {
                        assertionFailure("BlockLists error: Rule has unexpected format.")
                        continue
                }

                let domainExceptionsRegex: [NSRegularExpression]? = (trigger["unless-domain"] as? [String])?.flatMap { domain in
                        return wildcardDomainToRegex(domain: domain)
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

    // The 'unless-domain' rules use wildcard expressions, convert this to regex.
    private func wildcardDomainToRegex(domain: String) -> NSRegularExpression? {
        // Convert the domain exceptions into regular expressions.
        var regex = domain + "$"
        if regex.first == "*" {
            regex = "." + regex
        }
        regex = regex.replacingOccurrences(of: ".", with: "\\.")
        do {
            return try NSRegularExpression(pattern: regex, options: [])
        } catch {
            assertionFailure("BlockLists: \(error.localizedDescription)")
            return nil
        }
    }

    func urlIsInList(_ url: URL) -> BlockList? {
        let resourceString = url.absoluteString
        let resourceRange = NSMakeRange(0, resourceString.count)

        domainSearch: for rule in blockRules {
            // First, test the top-level filters to see if this URL might be blocked.
            if rule.regex.firstMatch(in: resourceString, options: .anchored, range: resourceRange) != nil {
                // Check the domain exceptions. If a domain exception matches, this filter does not apply.
                for domainRegex in (rule.domainExceptions ?? []) + whitelisted {
                    if domainRegex.firstMatch(in: resourceString, options: [], range: resourceRange) != nil {
                        continue domainSearch
                    }
                }

                return rule.list
            }
        }

        return nil
    }
}
