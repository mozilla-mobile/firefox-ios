/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client

import XCTest

class TPStatsBlocklistsTests: XCTestCase {
    var blocklists: TPStatsBlocklists!
    
    override func setUp() {
        super.setUp()
        
        blocklists = TPStatsBlocklists()
    }
    
    override func tearDown() {
        super.tearDown()
        blocklists = nil
    }
    
    func testLoadPerformance() {
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            blocklists.load()
            self.stopMeasuring()
        }
    }
    
    func testURLInListPerformance() {
        blocklists.load()
        
        let whitelistedRegexs = [".google.com"].compactMap { (domain) -> NSRegularExpression? in
            return wildcardContentBlockerDomainToRegex(domain: domain)
        }
        
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
            _ = blocklists.urlIsInList(URL(string: "https://www.firefox.com")!, whitelistedDomains: whitelistedRegexs)
            self.stopMeasuring()
        }
    }
    
    func testURLInList() {
        blocklists.load()
        
        func urlTest(_ urlString: String, _ whitelistedDomains: [String] = []) -> BlocklistName? {
            let whitelistedRegexs = whitelistedDomains.compactMap { (domain) -> NSRegularExpression? in
                return wildcardContentBlockerDomainToRegex(domain: domain)
            }

            return blocklists.urlIsInList(URL(string: urlString)!, whitelistedDomains: whitelistedRegexs)
        }
        
        XCTAssertEqual(urlTest("https://www.firefox.com"), nil)
        XCTAssertEqual(urlTest("https://2leep.com/track"), .advertising)
        XCTAssertEqual(urlTest("https://sub.2leep.com/ad"), .advertising)
        XCTAssertEqual(urlTest("https://admeld.com"), nil)
        XCTAssertEqual(urlTest("https://admeld.com/popup"), .advertising)
        XCTAssertEqual(urlTest("https://sub.admeld.com"), nil)
        XCTAssertEqual(urlTest("https://subadmeld.com"), nil)
        
        XCTAssertEqual(urlTest("https://aolanswers.com"), .content)
        XCTAssertEqual(urlTest("https://sub.aolanswers.com"), .content)
        XCTAssertEqual(urlTest("https://aolanswers.com/track"), .content)
        XCTAssertEqual(urlTest("https://aol.com.aolanswers.com"), .content)
        XCTAssertEqual(urlTest("https://aol.com.aolanswers.com", [".ers.com"]), nil)
        XCTAssertEqual(urlTest("https://games.com.aolanswers.com"), .content)
        XCTAssertEqual(urlTest("https://bluesky.com.aolanswers.com"), .content)
        
        XCTAssertEqual(urlTest("https://sub.xiti.com/track"), .analytics)
        XCTAssertEqual(urlTest("https://backtype.com"), .social)
        XCTAssertEqual(urlTest("https://backtype.com", [".firefox.com", ".e.com"]), nil)
    }
}
