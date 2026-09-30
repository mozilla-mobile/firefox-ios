// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Foundation

/// Reads the `vpn-serverlist` Remote Settings collection (the same collection desktop Firefox
/// uses — see `toolkit/components/ipprotection/IPProtectionServerlist.sys.mjs`) and exposes a
/// flat selection API. Records are Country-rooted: Country → City → Server → Protocol.
final class VPNServerlist: Sendable {
    static let collectionName = "vpn-serverlist"
    static let recommendedCountryCode = "REC"

    struct Country: Decodable {
        let name: String
        let code: String
        let cities: [City]
    }

    struct City: Decodable {
        let name: String
        let code: String
        let servers: [ServerRecord]
    }

    struct ServerRecord: Decodable {
        let hostname: String
        let port: Int?
        let quarantined: Bool?
        let protocols: [ProtocolRecord]?
    }

    struct ProtocolRecord: Decodable {
        let name: String
        let host: String?
        let port: Int?
        let scheme: String?
        let templateString: String?
    }

    private let client: RemoteSettingsClient
    private let logger: Logger

    init(rsService: RemoteSettingsService, logger: Logger = DefaultLogger.shared) {
        self.client = rsService.makeClient(collectionName: Self.collectionName)
        self.logger = logger
    }

    /// Picks a non-quarantined server. Prefers `countryCode` if given, then "REC", then the
    /// first country with any usable server. Returns the masque protocol's host/port when
    /// present (matches what we plumb into NWRelay), otherwise the server's top-level
    /// hostname/port (default 443).
    ///
    /// The "REC" step also covers a requested country whose servers are all quarantined, or one
    /// that has since been dropped from the collection, so a stale selection degrades to
    /// Recommended rather than to whatever country happens to be first in record order.
    func selectServer(countryCode: String? = nil) async -> VPNGuardian.Server? {
        let countries = await decodeCountries()
        let preferred = countryCode ?? Self.recommendedCountryCode
        if let pick = pickServer(in: countries.first(where: { $0.code == preferred })) {
            return pick
        }
        if preferred != Self.recommendedCountryCode,
           let pick = pickServer(in: countries.first(where: { $0.code == Self.recommendedCountryCode })) {
            return pick
        }
        for country in countries {
            if let pick = pickServer(in: country) { return pick }
        }
        return nil
    }

    func listCountries() async -> [Country] {
        return await decodeCountries()
    }

    private func decodeCountries() async -> [Country] {
        guard let records = client.getRecords(syncIfEmpty: true) else { return [] }
        let decoder = JSONDecoder()
        return records.compactMap { record in
            guard let data = record.fields.data(using: .utf8) else { return nil }
            return try? decoder.decode(Country.self, from: data)
        }
    }

    private func pickServer(in country: Country?) -> VPNGuardian.Server? {
        guard let country else { return nil }
        for city in country.cities {
            for server in city.servers where !(server.quarantined ?? false) {
                return flatten(server: server, city: city, country: country)
            }
        }
        return nil
    }

    private func flatten(server: ServerRecord, city: City, country: Country) -> VPNGuardian.Server {
        let masque = server.protocols?.first(where: { $0.name == "masque" })
        let host = masque?.host ?? server.hostname
        let portInt = masque?.port ?? server.port ?? 443
        let port = UInt16(clamping: portInt)
        return VPNGuardian.Server(
            hostname: host,
            port: port,
            city: city.code,
            countryCode: country.code
        )
    }
}
