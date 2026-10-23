// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import UIKit
import XCTest

final class OpenSearchEngineSearchConfigV3Tests: XCTestCase {
    private let v3GoogleTemplate = "https://www.google.com/search?client={partnerCode}&q={searchTerms}"

    // MARK: - Search URLs

    func testSearchURLForQuery_v3Engine_usesPartnerCodeForAccessPoint() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        partners: SearchPartnerResolverTests.googleIOSPartners)
        let expectedCodes: [SearchAccessPoint: String] = [
            .default: "ios-firefox-o-re",
            .context: "ios-firefox-cm-re",
            .widget: "ios-firefox-msw-re",
            .topsite: "ios-firefox-b-re"
        ]

        for (accessPoint, code) in expectedCodes {
            let url = subject.searchURLForQuery("kitten", accessPoint: accessPoint)
            XCTAssertEqual(url?.absoluteString, "https://www.google.com/search?client=\(code)&q=kitten")
        }
    }

    func testSearchURLForQuery_defaultsToDefaultAccessPoint() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        partners: SearchPartnerResolverTests.googleIOSPartners)

        XCTAssertEqual(subject.searchURLForQuery("kitten")?.absoluteString,
                       "https://www.google.com/search?client=ios-firefox-o-re&q=kitten")
    }

    func testSearchURLForQuery_v3EngineWithoutCode_omitsPartnerCodeParameter() throws {
        let partners = ["default": SearchEnginePartner(code: nil, telemetrySuffix: "com-nocodes")]
        let subject = try createSubject(searchTemplate: v3GoogleTemplate, partners: partners)

        XCTAssertEqual(subject.searchURLForQuery("kitten", accessPoint: .widget)?.absoluteString,
                       "https://www.google.com/search?q=kitten")
    }

    func testSearchURLForQuery_placeholderWithoutPartners_omitsPartnerCodeParameter() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate, partners: nil)

        XCTAssertEqual(subject.searchURLForQuery("kitten")?.absoluteString,
                       "https://www.google.com/search?q=kitten")
    }

    func testSearchURLForQuery_v2Engine_ignoresAccessPoint() throws {
        let template = "https://www.google.com/search?client=firefox-b-m&q={searchTerms}"
        let subject = try createSubject(searchTemplate: template, partners: nil)

        for accessPoint in SearchAccessPoint.allCases {
            XCTAssertEqual(subject.searchURLForQuery("kitten", accessPoint: accessPoint)?.absoluteString,
                           "https://www.google.com/search?client=firefox-b-m&q=kitten")
        }
    }

    func testRemovingPartnerCodeParameter() {
        let cases = [
            "https://a.com/s?client={partnerCode}&q={searchTerms}": "https://a.com/s?q={searchTerms}",
            "https://a.com/?q={searchTerms}&t={partnerCode}": "https://a.com/?q={searchTerms}",
            "https://a.com/s?a=1&client={partnerCode}&q={searchTerms}": "https://a.com/s?a=1&q={searchTerms}",
            "https://a.com/s?client={partnerCode}": "https://a.com/s",
            "https://a.com/s?client={partnerCode}#q={searchTerms}": "https://a.com/s#q={searchTerms}",
            "https://a.com/s?q={searchTerms}": "https://a.com/s?q={searchTerms}"
        ]

        for (template, expected) in cases {
            XCTAssertEqual(OpenSearchEngine.removingPartnerCodeParameter(from: template), expected)
        }
    }

    func testQueryForSearchURL_withPartnerCodePlaceholderInTemplate_returnsQuery() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        partners: SearchPartnerResolverTests.googleIOSPartners)
        let url = URL(string: "https://www.google.com/search?client=ios-firefox-o-re&q=kitten")

        XCTAssertEqual(subject.queryForSearchURL(url), "kitten")
    }

    // MARK: - Telemetry

    func testTelemetryIDForAccessPoint_v3Engine_usesAccessPointSuffix() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        telemetrySuffix: "ios-main",
                                        partners: SearchPartnerResolverTests.googleIOSPartners)

        XCTAssertEqual(subject.telemetryID(for: .widget), "google-ios-widget")
        XCTAssertEqual(subject.telemetryID(for: .default), subject.telemetryID)
    }

    func testTelemetryIDForAccessPoint_v2Engine_matchesTelemetryID() throws {
        let subject = try createSubject(searchTemplate: "https://a.com/s?q={searchTerms}",
                                        telemetrySuffix: "b-m",
                                        partners: nil)

        XCTAssertEqual(subject.telemetryID(for: .widget), "google-b-m")
    }

    func testTelemetryIDForAccessPoint_customEngine_isCustom() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        partners: SearchPartnerResolverTests.googleIOSPartners,
                                        isCustomEngine: true)

        XCTAssertEqual(subject.telemetryID(for: .widget), "custom")
    }

    // MARK: - NSCoding

    func testEncodeDecode_withPartners_preservesPartners() throws {
        let subject = try createSubject(searchTemplate: v3GoogleTemplate,
                                        partners: SearchPartnerResolverTests.googleIOSPartners)

        let decoded = try archiveAndUnarchive(subject)

        XCTAssertEqual(decoded.partners, SearchPartnerResolverTests.googleIOSPartners)
    }

    func testEncodeDecode_withoutPartners_decodesNilPartners() throws {
        let subject = try createSubject(searchTemplate: "https://a.com/s?q={searchTerms}", partners: nil)

        let decoded = try archiveAndUnarchive(subject)

        XCTAssertNil(decoded.partners)
    }

    // MARK: - Helpers

    private func createSubject(searchTemplate: String,
                               telemetrySuffix: String? = nil,
                               partners: [String: SearchEnginePartner]?,
                               isCustomEngine: Bool = false) throws -> OpenSearchEngine {
        let image = try XCTUnwrap(UIImage(named: "wikipedia",
                                          in: Bundle(for: OpenSearchEngineSearchConfigV3Tests.self),
                                          with: nil))
        return OpenSearchEngine(engineID: "google",
                                shortName: "Google",
                                telemetrySuffix: telemetrySuffix,
                                image: image,
                                searchTemplate: searchTemplate,
                                suggestTemplate: nil,
                                isCustomEngine: isCustomEngine,
                                partners: partners)
    }

    private func archiveAndUnarchive(_ engine: OpenSearchEngine) throws -> OpenSearchEngine {
        let data = try NSKeyedArchiver.archivedData(withRootObject: engine, requiringSecureCoding: true)
        let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [OpenSearchEngine.self, UIImage.self],
                                                             from: data) as? OpenSearchEngine
        return try XCTUnwrap(decoded)
    }
}
