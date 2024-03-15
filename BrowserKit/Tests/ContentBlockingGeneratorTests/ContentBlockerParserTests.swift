// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ContentBlockingGenerator

final class ContentBlockerParserTests: XCTestCase {
    private var parserData: ParserData!

    override func setUp() {
        super.setUp()
        self.parserData = ParserData()
    }

    override func tearDown() {
        super.tearDown()
        self.parserData = nil
    }

    func testParsingAdsFile() throws {
        let entityJson = try parserData.getDictData(from: .entity)
        let subject = DefaultContentBlockerParser()
        subject.parseEntityList(entityJson)

        let adsList = try parserData.getListData(from: .ads)
        let result = subject.parseCategoryList(adsList,
                                               actionType: .blockAll)

        // swiftlint:disable line_length
        let expectedFirstLine = """
        {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?2leep\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*2leep.com\"]}}
        """

        let expectedSecondLine = """
               {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?adnologies\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*adnologies.com\",\"*heias.com\"]}}
               """

        let expectedThirdLine = """
               {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?heias\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*adnologies.com\",\"*heias.com\"]}}
               """

        let expectedFourthLine = """
               {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?365media\\\\.com\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*aggregateintelligence.com\"]}}
               """

        let expectedFifthLine = """
                {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?adfox\\\\.yandex\\\\.ru\",\"load-type\":[\"third-party\"],\"unless-domain\":[\"*kinopoisk.ru\",\"*moikrug.ru\",\"*yadi.sk\",\"*yandex.by\",\"*yandex.com\",\"*yandex.com.tr\",\"*yandex.ru\",\"*yandex.st\",\"*yandex.ua\"]}}
                """
        // swiftlint:enable line_length
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], expectedFirstLine)
        XCTAssertEqual(result[1], expectedSecondLine)
        XCTAssertEqual(result[2], expectedThirdLine)
        XCTAssertEqual(result[3], expectedFourthLine)
        XCTAssertEqual(result[4], expectedFifthLine)
    }

    func testParsingAdsFile_withoutEntity() throws {
        let entityJson = try parserData.getDictData(from: .emptyEntity)
        let subject = DefaultContentBlockerParser()
        subject.parseEntityList(entityJson)

        let adsList = try parserData.getListData(from: .ads)
        let result = subject.parseCategoryList(adsList,
                                               actionType: .blockAll)

        // swiftlint:disable line_length
        let firstLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?2leep\\\\.com","load-type":["third-party"]}}
        """

        let secondLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?adnologies\\\\.com","load-type":["third-party"]}}
        """

        let thirdLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?heias\\\\.com","load-type":["third-party"]}}
        """

        let fourthLine = """
        {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?365media\\\\.com","load-type":["third-party"]}}
        """
        let fifthLine = """
        {\"action\":{\"type\":\"block\"},\"trigger\":{\"url-filter\":\"^https?://([^/]+\\\\.)?adfox\\\\.yandex\\\\.ru\",\"load-type\":[\"third-party\"]}}
        """
        // swiftlint:enable line_length
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], firstLine)
        XCTAssertEqual(result[1], secondLine)
        XCTAssertEqual(result[2], thirdLine)
        XCTAssertEqual(result[3], fourthLine)
        XCTAssertEqual(result[4], fifthLine)
    }
}
