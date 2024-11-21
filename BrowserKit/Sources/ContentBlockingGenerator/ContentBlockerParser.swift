// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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

        entitiesRaw.forEach { entitiesRawItem in
            guard let entitiesDict = entitiesRawItem.value as? [String: [String]],
                  let properties = entitiesDict["properties"],
                  let resources = entitiesDict["resources"] else {
                return
            }
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

    /// Create the line for a propertie's resource if an entity information is present,
    /// we can build the line using unless-domain (whitelisting).
    /// - Parameters:
    ///   - property: The resource of an entity, example "2leep.com"
    ///   - actionType: "block" or "block-all"
    /// - Returns: the webkit format file content for that entity resource
    private func createLine(for resource: String,
                            actionType: ActionType) -> String {
        let filter = buildUrlFilter(resource)
        let entity = entities[resource]
        if let entity = entity {
            return buildOutput(with: entity, urlFilter: filter, actionType: actionType)
        } else if let entity = findEntity(for: resource) {
            return buildOutput(with: entity, urlFilter: filter, actionType: actionType)
        }

        // No entity found for resource, create line without unless-domain
        let line = buildOutputLine(urlFilter: filter,
                                   unlessDomain: "",
                                   actionType: actionType)
        return line
    }

    private func findEntity(for resource: String) -> Entity? {
        // Since there was no direct mapping of the resource to find the entity, we need to check if any
        // the entities keys is contained as part of the resource we're creating the line for
        var foundEntity: Entity?
        for keyResource in entities.keys where resource.contains(keyResource) {
            foundEntity = entities[keyResource]
            break
        }

        return foundEntity
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

    private func buildOutput(with entity: Entity, urlFilter: String, actionType: ActionType) -> String {
        let unlessDomain = buildUnlessDomain(entity.properties)
        return buildOutputLine(urlFilter: urlFilter,
                               unlessDomain: unlessDomain,
                               actionType: actionType)
    }

    private func buildOutputLine(urlFilter: String,
                                 unlessDomain: String,
                                 actionType: ActionType) -> String {
        let unlessDomainSection = unlessDomain.isEmpty ? "" : ",\"unless-domain\":\(unlessDomain)"
        // swiftlint:disable line_length
        let line = """
                    {"action":{"type":\(actionType.webKitFormat)},"trigger":{"url-filter":"\(urlFilter)","load-type":["third-party"]\(unlessDomainSection)}}
                    """
        // swiftlint:enable line_length
        return line
    }
}
