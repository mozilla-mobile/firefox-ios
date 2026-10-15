// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The search access points for iOS that search-config-v3 can assign a partner code and
/// telemetry suffix to. Raw values match the keys of the configuration's `partner`.
enum SearchAccessPoint: String, CaseIterable, Sendable {
    /// Address bar searches, and the default fallback.
    case `default`
    /// Searches from context (long-press) menu.
    case context
    /// Searches from home screen widget.
    case widget
    /// Searches from Google top site shortcut.
    case topsite
}

/// The partner code and telemetry suffix that search-config-v3 provides for a single SAP. This mirrors
/// Rust `SearchEnginePartnerDetails` so the client doesn't depend on generated types and
/// can persist it via Codable.
struct SearchEnginePartner: Codable, Equatable, Sendable {
    let code: String?
    let telemetrySuffix: String?
}

/// Partner code and telemetry ID to use for a search started from a given access point.
struct SearchPartnerResolution: Equatable, Sendable {
    /// The value to insert for `{partnerCode}`, or `nil` if partner code param must be omitted.
    let partnerCode: String?
    /// Engine identifier followed by `-<telemetrySuffix>` when a suffix is provided.
    let telemetryID: String
}

enum SearchPartnerResolver {
    /// Selects partner code and telemetry ID for a search, following the search-config-v3 rules:
    /// - The entry for the access point is used if present, otherwise the `default` entry.
    /// - A missing or empty code means the partner code parameter is omitted.
    /// - A missing or empty telemetry suffix means the telemetry ID is just the engine identifier.
    ///
    /// - Parameters:
    ///   - engineIdentifier: The configuration identifier of the engine, e.g. `google`.
    ///   - partners: The engine's partner map, keyed by access point name. `nil` if the engine has no partner details.
    ///   - accessPoint: The access point the search was started from.
    static func resolve(engineIdentifier: String,
                        partners: [String: SearchEnginePartner]?,
                        accessPoint: SearchAccessPoint) -> SearchPartnerResolution {
        let partner = partners?[accessPoint.rawValue] ?? partners?[SearchAccessPoint.default.rawValue]

        let partnerCode = partner?.code.flatMap { $0.isEmpty ? nil : $0 }

        let telemetryID: String
        if let suffix = partner?.telemetrySuffix, !suffix.isEmpty {
            telemetryID = "\(engineIdentifier)-\(suffix)"
        } else {
            telemetryID = engineIdentifier
        }

        return SearchPartnerResolution(partnerCode: partnerCode, telemetryID: telemetryID)
    }
}
