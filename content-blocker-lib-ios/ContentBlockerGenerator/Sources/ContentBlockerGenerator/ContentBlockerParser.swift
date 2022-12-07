// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

// TODO: Laurie - Document
class ContentBlockerParser {

    // Key is each property of an entity, so each resources for an entity is easily accessible
    private var entities = [String: Entity]()

    func parseEntityList(json: [String: Any]) {
        let entitiesRaw = json["entities"]! as! [String: Any]
        entitiesRaw.forEach {
            let properties = ($0.value as! [String: [String]])["properties"]!
            let resources = ($0.value as! [String: [String]])["resources"]!
            let entity = Entity(properties: properties, resources: resources)
            properties.forEach {
                entities[$0] = entity
            }
        }
    }

    func parseFile(json: [String],
                   actionType: ActionType) -> [String] {

        var result = [String]()
        for property in json {
            let line = createLine(for: property, actionType: actionType)
            result.append(line)
        }
        return result
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
