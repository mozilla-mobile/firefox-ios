// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

class ContentBlockerParser {

    // Key are the companies (entities) with a list of related domains (properties) as values
    private var companyToRelatedDomains = [String: [String]]()

    func parseEntityList(json: [String: Any]) {
        let entities = json["entities"]! as! [String: Any]
        entities.forEach {
            let company = $0.key
            let related = ($0.value as! [String: [String]])["properties"]!
            companyToRelatedDomains[company] = related
        }
    }

    // For unless domain we used company name from black list to map into entity list
    // TODO: Can we use the domain instead company name for that ? Asked a question to understand this better.

    /// - Parameters:
    ///   - categoryItem: "Advertisers", "Analytics" etc
    ///   - actionType: "block" or "block-all"
    /// - Returns: the webkit format file content for that category item
    func handleCategoryItem(_ categoryItem: Any,
                            actionType: ActionType) -> [String] {

        /* example of input
         {
         "10Web": {
         "https://10web.io/": [
         "10web.io"
         ]
         }
         }
         */
        let categoryItem = categoryItem as! [String: [String: Any]]
        var result = [String]()
        assert(categoryItem.count == 1)

        // "10Web"
        let companyName = categoryItem.first!.key

        /* [
         "10web.io",
         "example.com"
         ] */
        let relatedDomains = companyToRelatedDomains[companyName, default: []]
        // ["*10web.io","*example.com"]
        let unlessDomain = buildUnlessDomain(relatedDomains)

        // ["https://10web.io/"]
        let entry = categoryItem.first!.value.first(where: { $0.key.hasPrefix("http") || $0.key.hasPrefix("www.") })!
        // ["https://10web.io/"]
        let domains = entry.value as! [String]
        domains.forEach {
            // "^https?://([^/]+\\.)?10web\\.io"
            let filter = buildUrlFilter($0)
            let line = buildOutputLine(urlFilter: filter,
                                       unlessDomain: unlessDomain,
                                       actionType: actionType)
            // "action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\.)?10web\\.io","load-type":["third-party"],"unless-domain":["*10web.io","*example.com"]}},
            result.append(line)
        }
        return result
    }

    func parseFile(json: [String: Any],
                   actionType: ActionType,
                   categoryTitle: FileCategory) -> [String] {
        // all categories json
        let categories = json["categories"]! as! [String: Any]
        var result = [String]()

        // takes the category json for "analytics" for example
        let category = categories[categoryTitle.rawValue] as! [Any]
        // loops over each item in that category
        category.forEach {
            result += handleCategoryItem($0, actionType: actionType)
        }
        return result
    }

    // TODO: New method, assumes for now there's no white listing. Is this proper?
    // TODO: Rename and document
    func newParseFile(json: [String],
                      actionType: ActionType,
                      categoryTitle: FileCategory) -> [String] {

        var result = [String]()
        for domain in json {
            let f = buildUrlFilter(domain)
            let line = buildOutputLine(urlFilter: f, unlessDomain: "", actionType: actionType)
            result.append(line)
        }
        return result
    }

    // MARK: - Private

    // TODO: Needed?
    private func buildUnlessDomain(_ domains: [String]) -> String {
        guard !domains.isEmpty else { return "" }
        let result = domains.reduce("", { $0 + "\"*\($1)\"," }).dropLast()
        return "[" + result + "]"
    }

    private func buildUrlFilter(_ domain: String) -> String {
        let prefix = "^https?://([^/]+\\\\.)?"
        return prefix + domain.replacingOccurrences(of: ".", with: "\\\\.")
    }

    private func buildOutputLine(urlFilter: String,
                                 unlessDomain: String,
                                 actionType: ActionType) -> String {
        let unlessDomainSection = unlessDomain.isEmpty ? "" : ",\"unless-domain\":\(unlessDomain)"
        let result = """
                    {"action":{"type":\(actionType.webKitFormat)},"trigger":{"url-filter":"\(urlFilter)","load-type":["third-party"]\(unlessDomainSection)}}
                    """
        return result
    }
}
