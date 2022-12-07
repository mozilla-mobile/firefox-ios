// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
@testable import ContentBlockerGenerator

final class ContentBlockerParserTests: XCTestCase {

    func testParsingAdsFile() throws {
        let entityJson = getDictData(from: ParserData.entitylist)
        let subject = ContentBlockerParser()
        subject.parseEntityList(json: entityJson)

        let adsList = getListData(from: ParserData.adsTrackDigest256)
        let result = subject.parseFile(json: adsList,
                                       actionType: .blockAll)

        let expectedFirstLine = """
        {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?2leep\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*2leep.com\"]}}
        """

        let expectedSecondLine = """
               {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?adnologies\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*adnologies.com\",\"*heias.com\"]}}
               """

        let expectedThirdLine = """
               {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?heias\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*adnologies.com\",\"*heias.com\"]}}
               """
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], expectedFirstLine)
        XCTAssertEqual(result[1], expectedSecondLine)
        XCTAssertEqual(result[2], expectedThirdLine)
    }

    func testParsingAdsFile_withoutEntity() throws {
        let entityJson = getDictData(from: ParserData.emptyEntitylist)
        let subject = ContentBlockerParser()
        subject.parseEntityList(json: entityJson)

        let adsList = getListData(from: ParserData.adsTrackDigest256)
        let result = subject.parseFile(json: adsList,
                                       actionType: .blockAll)

        let firstLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?2leep\\\\.com","load-type":["third-party"]}}
        """

        let secondLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?adnologies\\\\.com","load-type":["third-party"]}}
        """

        let thirdLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?heias\\\\.com","load-type":["third-party"]}}
        """
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], firstLine)
        XCTAssertEqual(result[1], secondLine)
        XCTAssertEqual(result[2], thirdLine)
    }
}

// MARK: - Helpers
private extension ContentBlockerParserTests {
    func getDictData(from dict: String) -> [String: Any] {
        return try! JSONSerialization.jsonObject(with: dict.data(using: .utf8)!,
                                                 options: []) as! [String: Any]
    }

    func getListData(from list: String) -> [String] {
        return try! JSONSerialization.jsonObject(with: list.data(using: .utf8)!,
                                                 options: []) as! [String]
    }
}

// MARK: - Data
private struct ParserData {
    static let adsTrackDigest256 = """
[
  "2leep.com",
  "adnologies.com",
  "heias.com"
]
"""

    static let entitylist = """
{
"license": "Copyright 2010-2020 Disconnect, Inc.",
"entities":
    {
        "2leep.com": { "properties": [ "2leep.com" ], "resources": [ "2leep.com" ] },
        "adnologies": { "properties": [ "adnologies.com", "heias.com" ], "resources": [ "adnologies.com", "heias.com" ] }
    }
}
"""

    static let emptyEntitylist = """
{
"license": "Copyright 2010-2020 Disconnect, Inc.",
"entities":
    {
    }
}
"""
}
