// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import XCTest

final class SearchPartnerResolverTests: XCTestCase {
    static let googleIOSPartners: [String: SearchEnginePartner] = [
        "default": SearchEnginePartner(code: "ios-firefox-o-re", telemetrySuffix: "ios-main"),
        "context": SearchEnginePartner(code: "ios-firefox-cm-re", telemetrySuffix: "ios-context"),
        "widget": SearchEnginePartner(code: "ios-firefox-msw-re", telemetrySuffix: "ios-widget"),
        "topsite": SearchEnginePartner(code: "ios-firefox-b-re", telemetrySuffix: "ios-topsite")
    ]

    func testAccessPointRawValues_matchConfigurationKeys() {
        XCTAssertEqual(SearchAccessPoint.allCases.map(\.rawValue), ["default", "context", "widget", "topsite"])
    }

    func testResolve_withAccessPointEntry_usesThatEntry() {
        let expected: [SearchAccessPoint: SearchPartnerResolution] = [
            .default: SearchPartnerResolution(partnerCode: "ios-firefox-o-re", telemetryID: "google-ios-main"),
            .context: SearchPartnerResolution(partnerCode: "ios-firefox-cm-re", telemetryID: "google-ios-context"),
            .widget: SearchPartnerResolution(partnerCode: "ios-firefox-msw-re", telemetryID: "google-ios-widget"),
            .topsite: SearchPartnerResolution(partnerCode: "ios-firefox-b-re", telemetryID: "google-ios-topsite")
        ]

        for accessPoint in SearchAccessPoint.allCases {
            let result = SearchPartnerResolver.resolve(engineIdentifier: "google",
                                                       partners: Self.googleIOSPartners,
                                                       accessPoint: accessPoint)
            XCTAssertEqual(result, expected[accessPoint], "Unexpected resolution for \(accessPoint)")
        }
    }

    func testResolve_withoutAccessPointEntry_fallsBackToDefault() {
        let partners = ["default": SearchEnginePartner(code: "fpas", telemetrySuffix: "")]

        let result = SearchPartnerResolver.resolve(engineIdentifier: "ddg", partners: partners, accessPoint: .widget)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: "fpas", telemetryID: "ddg"))
    }

    func testResolve_withNoPartners_omitsCodeAndUsesIdentifier() {
        let result = SearchPartnerResolver.resolve(engineIdentifier: "mercadolibre-ar",
                                                   partners: nil,
                                                   accessPoint: .widget)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: nil, telemetryID: "mercadolibre-ar"))
    }

    func testResolve_withEmptyCodeForAccessPoint_omitsCodeWithoutFallingBackToDefault() {
        var partners = Self.googleIOSPartners
        partners["widget"] = SearchEnginePartner(code: "", telemetrySuffix: "ios-nocodes")

        let result = SearchPartnerResolver.resolve(engineIdentifier: "google", partners: partners, accessPoint: .widget)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: nil, telemetryID: "google-ios-nocodes"))
    }

    func testResolve_withDefaultEntryWithoutCode_omitsCodeAndUsesSuffix() {
        let partners = ["default": SearchEnginePartner(code: nil, telemetrySuffix: "com-nocodes")]

        let result = SearchPartnerResolver.resolve(engineIdentifier: "google", partners: partners, accessPoint: .context)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: nil, telemetryID: "google-com-nocodes"))
    }

    func testResolve_withNilSuffix_usesIdentifier() {
        let partners = ["default": SearchEnginePartner(code: "ffab", telemetrySuffix: nil)]

        let result = SearchPartnerResolver.resolve(engineIdentifier: "bing", partners: partners, accessPoint: .default)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: "ffab", telemetryID: "bing"))
    }

    func testResolve_withoutAccessPointOrDefaultEntry_omitsCodeAndUsesIdentifier() {
        let partners = ["newtab": SearchEnginePartner(code: "desktop-only", telemetrySuffix: "newtab")]

        let result = SearchPartnerResolver.resolve(engineIdentifier: "google", partners: partners, accessPoint: .widget)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: nil, telemetryID: "google"))
    }

    func testResolve_ignoresUnknownAccessPointKeys() {
        var partners = Self.googleIOSPartners
        partners["newtab_search_widget"] = SearchEnginePartner(code: "firefox-b-exp1", telemetrySuffix: "b-exp1")

        let result = SearchPartnerResolver.resolve(engineIdentifier: "google", partners: partners, accessPoint: .default)

        XCTAssertEqual(result, SearchPartnerResolution(partnerCode: "ios-firefox-o-re", telemetryID: "google-ios-main"))
    }

    func testSearchEnginePartner_codableRoundTrip() throws {
        let data = try JSONEncoder().encode(Self.googleIOSPartners)
        let decoded = try JSONDecoder().decode([String: SearchEnginePartner].self, from: data)

        XCTAssertEqual(decoded, Self.googleIOSPartners)
    }
}
