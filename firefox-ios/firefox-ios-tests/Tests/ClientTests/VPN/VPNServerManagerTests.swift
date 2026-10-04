// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import TestKit
import XCTest
@testable import Client

@MainActor
final class VPNServerManagerTests: XCTestCase {
    func testSelectServer_withoutCountryCode_prefersRecommended() async throws {
        let subject = createSubject(countries: [
            country(code: "US", servers: [server(hostname: "us.example")]),
            country(code: "REC", servers: [server(hostname: "rec.example")])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(try XCTUnwrap(result).hostname, "rec.example")
    }

    func testSelectServer_withCountryCode_returnsServerFromThatCountry() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [server(hostname: "rec.example")]),
            country(code: "DE", cityCode: "BER", servers: [server(hostname: "de.example")])
        ])

        let result = await subject.selectServer(countryCode: "DE")

        XCTAssertEqual(result?.hostname, "de.example")
        XCTAssertEqual(result?.city, "BER")
        XCTAssertEqual(result?.countryCode, "DE")
    }

    func testSelectServer_requestedCountryAllQuarantined_fallsBackToRecommended() async throws {
        let subject = createSubject(countries: [
            country(code: "US", servers: [server(hostname: "us.example")]),
            country(code: "DE", servers: [server(hostname: "de.example", quarantined: true)]),
            country(code: "REC", servers: [server(hostname: "rec.example")])
        ])

        let result = await subject.selectServer(countryCode: "DE")

        XCTAssertEqual(try XCTUnwrap(result).hostname, "rec.example")
    }

    func testSelectServer_requestedCountryMissing_fallsBackToRecommended() async throws {
        let subject = createSubject(countries: [
            country(code: "US", servers: [server(hostname: "us.example")]),
            country(code: "REC", servers: [server(hostname: "rec.example")])
        ])

        let result = await subject.selectServer(countryCode: "FR")

        XCTAssertEqual(try XCTUnwrap(result).hostname, "rec.example")
    }

    func testSelectServer_noUsableRecommended_fallsBackToFirstUsableCountry() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [server(hostname: "rec.example", quarantined: true)]),
            country(code: "US", servers: [server(hostname: "us.example", quarantined: true)]),
            country(code: "DE", servers: [server(hostname: "de.example")])
        ])

        let result = await subject.selectServer(countryCode: "FR")

        XCTAssertEqual(try XCTUnwrap(result).hostname, "de.example")
    }

    func testSelectServer_skipsQuarantinedServersAcrossCities() async throws {
        let subject = createSubject(countries: [
            Country(code: "REC", cities: [
                City(code: "A", servers: [server(hostname: "a.example", quarantined: true)]),
                City(code: "B", servers: [
                    server(hostname: "b1.example", quarantined: true),
                    server(hostname: "b2.example", quarantined: false)
                ])
            ])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(result?.hostname, "b2.example")
        XCTAssertEqual(result?.city, "B")
    }

    func testSelectServer_allServersQuarantined_returnsNil() async {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [server(hostname: "rec.example", quarantined: true)])
        ])

        let result = await subject.selectServer()

        XCTAssertNil(result)
    }

    func testSelectServer_prefersMasqueProtocolHostAndPort() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [
                server(
                    hostname: "rec.example",
                    port: 443,
                    protocols: [
                        ProtocolRecord(name: "wireguard", host: "wg.example", port: 51820),
                        ProtocolRecord(name: "masque", host: "masque.example", port: 2499)
                    ]
                )
            ])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(result?.hostname, "masque.example")
        XCTAssertEqual(result?.port, 2499)
    }

    func testSelectServer_masqueWithoutHostOrPort_fallsBackToServerHostnameAndPort() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [
                server(hostname: "rec.example", port: 8443, protocols: [ProtocolRecord(name: "masque")])
            ])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(result?.hostname, "rec.example")
        XCTAssertEqual(result?.port, 8443)
    }

    func testSelectServer_withoutAnyPort_defaultsTo443() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [server(hostname: "rec.example")])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(result?.port, 443)
    }

    func testSelectServer_portOutOfRange_isClamped() async throws {
        let subject = createSubject(countries: [
            country(code: "REC", servers: [server(hostname: "rec.example", port: 70_000)])
        ])

        let result = await subject.selectServer()

        XCTAssertEqual(result?.port, UInt16.max)
    }

    func testSelectServer_noRecords_returnsNil() async {
        let client = MockRemoteSettingsClient()
        client.returnsNilRecords = true
        let subject = createSubject(client: client)

        let result = await subject.selectServer()

        XCTAssertNil(result)
    }

    func testListCountries_skipsUndecodableRecords() async throws {
        let validFields = try encode(country(code: "REC", servers: [server(hostname: "rec.example")]))
        let client = MockRemoteSettingsClient(
            collectionName: VPNServerManager.collectionName,
            records: [
                record(id: "invalid", fields: "{\"name\": \"missing fields\"}"),
                record(id: "valid", fields: validFields)
            ]
        )
        let subject = createSubject(client: client)

        let result = await subject.listCountries()

        XCTAssertEqual(result.map(\.code), ["REC"])
    }

    // MARK: - Helpers

    private func createSubject(countries: [Country]) -> VPNServerManager {
        let records = countries.enumerated().map { index, country in
            record(id: "\(index)", fields: (try? encode(country)) ?? "")
        }
        return createSubject(
            client: MockRemoteSettingsClient(collectionName: VPNServerManager.collectionName, records: records)
        )
    }

    private func createSubject(client: MockRemoteSettingsClient) -> VPNServerManager {
        let subject = VPNServerManager(client: client, logger: MockLogger())
        trackForMemoryLeaks(subject)
        return subject
    }

    private struct Country: Encodable {
        let name = "Country"
        let code: String
        let cities: [City]
    }

    private struct City: Encodable {
        let name = "City"
        let code: String
        let servers: [Server]
    }

    private struct Server: Encodable {
        let hostname: String
        let port: Int?
        let quarantined: Bool?
        let protocols: [ProtocolRecord]?
    }

    private struct ProtocolRecord: Encodable {
        let name: String
        var host: String?
        var port: Int?
    }

    private func country(code: String, cityCode: String = "CITY", servers: [Server]) -> Country {
        return Country(code: code, cities: [City(code: cityCode, servers: servers)])
    }

    private func server(
        hostname: String,
        port: Int? = nil,
        quarantined: Bool? = nil,
        protocols: [ProtocolRecord]? = nil
    ) -> Server {
        return Server(hostname: hostname, port: port, quarantined: quarantined, protocols: protocols)
    }

    private func encode(_ country: Country) throws -> String {
        return try XCTUnwrap(String(data: JSONEncoder().encode(country), encoding: .utf8))
    }

    private func record(id: String, fields: String) -> RemoteSettingsRecord {
        return RemoteSettingsRecord(id: id, lastModified: 0, deleted: false, attachment: nil, fields: fields)
    }
}
