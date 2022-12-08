// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// Content Blocker Parser ingests the entity list first to then be able to parse the different file categories.
protocol ContentBlockerParser {
    func parseEntityList(_ entitiesList: [String: Any])
    func parseCategoryList(_ categoryList: [String], actionType: ActionType) -> [String]
}

class DefaultContentBlockerParser: ContentBlockerParser {

    // Key is each resource of an entity, so each properties for an entity's resource is easily accessible
    private var entities = [String: Entity]()

    func parseEntityList(_ entitiesList: [String: Any]) {
        guard let entitiesRaw = entitiesList["entities"] as? [String: Any] else {
            return
        }

        entitiesRaw.forEach {
            let properties = ($0.value as! [String: [String]])["properties"]!
            let resources = ($0.value as! [String: [String]])["resources"]!
            let entity = Entity(properties: properties, resources: resources)
            resources.forEach {
                entities[$0] = entity
            }
        }
    }

    func parseCategoryList(_ categoryList: [String],
                           actionType: ActionType) -> [String] {

        var lines = [String]()
        for property in categoryList {
            let line = createLine(for: property, actionType: actionType)
            lines.append(line)
        }
        return lines
    }

    // MARK: - Private

    /// Create the line for a property, if an entity information is present, we can build the line using unless-domain
    /// - Parameters:
    ///   - property: The property of an entity, example "2leep.com"
    ///   - actionType: "block" or "block-all"
    /// - Returns: the webkit format file content for that entity property
    private func createLine(for property: String,
                            actionType: ActionType) -> String {

        let filter = buildUrlFilter(property)
        let propertyEntity = entities[property]
        guard let propertyEntity = propertyEntity else {
            let line = buildOutputLine(urlFilter: filter,
                                       unlessDomain: "",
                                       actionType: actionType)
            return line
        }

        let unlessDomain = buildUnlessDomain(propertyEntity.properties)
        return buildOutputLine(urlFilter: filter,
                               unlessDomain: unlessDomain,
                               actionType: actionType)
    }

    private func buildUnlessDomain(_ domains: [String]) -> String {
        guard !domains.isEmpty else { return "" }
        let unlessDomain = domains.reduce("", { $0 + "\"*\($1)\"," }).dropLast()
        return "[" + unlessDomain + "]"
    }

    private func buildUrlFilter(_ domain: String) -> String {
        let prefix = "^https?://([^/]+\\\\.)?"
        return prefix + domain.replacingOccurrences(of: ".", with: "\\\\.")
    }

    private func buildOutputLine(urlFilter: String,
                                 unlessDomain: String,
                                 actionType: ActionType) -> String {
        let unlessDomainSection = unlessDomain.isEmpty ? "" : ",\"unless-domain\":\(unlessDomain)"
        let line = """
                    {"action":{"type":\(actionType.webKitFormat)},"trigger":{"url-filter":"\(urlFilter)","load-type":["third-party"]\(unlessDomainSection)}}
                    """
        return line
    }
}
