// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// SAP for iOS that search-config-v3 can assign a partner code and telemetry suffix to.
/// Raw values match the keys of the configuration's `partner`.
enum SearchAccessPoint: String, CaseIterable, Sendable {
    /// Address bar searches, also the default fallback.
    case `default`
    /// Context (long-press) menu.
    case context
    /// Home screen widget.
    case widget
    /// Google top site shortcut.
    case topsite
}

struct SearchEnginePartner: Codable, Equatable, Sendable {
    let code: String?
    let telemetrySuffix: String?
}

struct SearchPartnerResolution: Equatable, Sendable {
    /// The value to insert for `{partnerCode}`, or `nil` if partner code param must be omitted.
    let partnerCode: String?
    /// Engine identifier followed by `-<telemetrySuffix>` when a suffix is provided.
    let telemetryID: String
}

enum SearchPartnerResolver {
    /// Selects partner code and telemetry ID for a search, following the search-config-v3 rules:
    /// - Entry for the access point if present, otherwise `default`.
    /// - A missing or empty code means the partner code parameter is omitted.
    /// - A missing or empty telemetry suffix means the telemetry ID is just the engine identifier.
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
