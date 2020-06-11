/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum Action: String {
    case blockAll = "\"block\""
    case blockCookies = "\"block-cookies\""
}

public enum CategoryTitle: String, CaseIterable {
    case Advertising
    case Analytics
    case Social
    // case Fingerprinting // not used, we have special fingerprinting list instead
    case Disconnect
    case Cryptomining
    case Content
}

public class ContentBlockerGenLib {
    var companyToRelatedDomains = [String: [String]]()

    public init(entityListJson: [String: Any]) {
        parseEntityList(json: entityListJson)
    }

    func parseEntityList(json: [String: Any]) {
        json.forEach {
            let company = $0.key
            let related = ($0.value as! [String: [String]])["properties"]!
            companyToRelatedDomains[company] = related
        }
    }

    func buildUnlessDomain(_ domains: [String]) -> String {
        guard domains.count > 0 else { return "" }
        let result = domains.reduce("", { $0 + "\"*\($1)\"," }).dropLast()
        return "[" + result + "]"
    }

    func buildUrlFilter(_ domain: String) -> String {
        let prefix = "^https?://([^/]+\\\\.)?"
        return prefix + domain.replacingOccurrences(of: ".", with: "\\\\.")
    }

    func buildOutputLine(urlFilter: String, unlessDomain: String, action: Action) -> String {
        let unlessDomainSection = unlessDomain.isEmpty ? "" : ",\"unless-domain\":\(unlessDomain)"
        let result = """
                    {"action":{"type":\(action.rawValue)},"trigger":{"url-filter":"\(urlFilter)","load-type":["third-party"]\(unlessDomainSection)}}
                    """
        return result
    }

    public func handleCategoryItem(_ categoryItem: Any, action: Action) -> [String] {
        let categoryItem = categoryItem as! [String: [String: Any]]
        var result = [String]()
        assert(categoryItem.count == 1)
        let companyName = categoryItem.first!.key

        let relatedDomains = companyToRelatedDomains[companyName, default: []]
        let unlessDomain = buildUnlessDomain(relatedDomains)

        let entry = categoryItem.first!.value.first(where: { $0.key.hasPrefix("http") || $0.key.hasPrefix("www.") })!
        // let companyDomain = entry.key // noting that companyDomain is not used anywhere
        let domains = entry.value as! [String]
        domains.forEach {
            let f = buildUrlFilter($0)
            let line = buildOutputLine(urlFilter: f, unlessDomain: unlessDomain, action: action)
            result.append(line)
        }
        return result
    }

    public func parseBlocklist(json: [String: Any], action: Action, categoryTitle: CategoryTitle) -> [String] {
        let categories = json["categories"]! as! [String: Any]
        var result = [String]()
        let category = categories[categoryTitle.rawValue] as! [Any]
        category.forEach {
            result += handleCategoryItem($0, action: action)
        }

        return result
    }

    public func parseFingerprintingList(json: [String]) -> [String] {
        var result = [String]()
        for domain in json {
            let f = buildUrlFilter(domain)
            let line = buildOutputLine(urlFilter: f, unlessDomain: "", action: .blockAll)
            result.append(line)
        }
        return result
    }
}

