/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import ContentBlockerGenLib

let blacklist = """
{
"license": "Copyright 2010-2019 Disconnect, Inc.",
"categories": {
  "Advertising": [
    {
        "adnologies": { "http://www.adnologies.com/": [ "adnologies.com" ], "performance": "true" },
    }
  ]
}}
"""

let entitylist = """
{
    "2leep.com": { "properties": [ "2leep.com" ], "resources": [ "2leep.com" ] },
    "adnologies": { "properties": [ "adnologies.com", "heias.com" ], "resources": [ "adnologies.com", "heias.com" ] }
}
"""

final class ContentBlockerGenTests: XCTestCase {
    func testParsing() throws {
        let entityJson = try! JSONSerialization.jsonObject(with: entitylist.data(using: .utf8)!, options: []) as! [String: Any]

        let contentBlocker = ContentBlockerGenLib(entityListJson: entityJson)

        let json = try! JSONSerialization.jsonObject(with: blacklist.data(using: .utf8)!, options: []) as! [String: Any]
        let categories = json["categories"]! as! [String: Any]
        let category = categories[CategoryTitle.Advertising.rawValue] as! [Any]
        var result = [String]()
        category.forEach() {
            result += contentBlocker.handleCategoryItem($0, action: .blockAll)
        }

        let test = """
               {"action":{"type":"block"},"trigger":{"url-filter":"^https?://([^/]+\\\\.)?adnologies\\\\.com","load-type":["third-party"],"unless-domain":["*adnologies.com","*heias.com"]}}
               """
        XCTAssert(result.first! == test)
    }

    static var allTests = [
        ("testParsing", testParsing),
    ]
}
