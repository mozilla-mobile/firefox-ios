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
            for _ in 0..<100 {
                _ = blocklists.urlIsInList(URL(string: "https://www.firefox.com")!, whitelistedDomains: whitelistedRegexs)
            }
            self.stopMeasuring()
        }
    }
    
    func testURLInList() {
        blocklists.load()
        
        func blocklist(_ urlString: String, _ whitelistedDomains: [String] = []) -> BlocklistName? {
            let whitelistedRegexs = whitelistedDomains.compactMap { (domain) -> NSRegularExpression? in
                return wildcardContentBlockerDomainToRegex(domain: domain)
            }

            return blocklists.urlIsInList(URL(string: urlString)!, whitelistedDomains: whitelistedRegexs)
        }
        
        XCTAssertEqual(blocklist("https://www.firefox.com"), nil)
        XCTAssertEqual(blocklist("https://2leep.com/track"), .advertising)
        XCTAssertEqual(blocklist("https://sub.2leep.com/ad"), .advertising)
        XCTAssertEqual(blocklist("https://admeld.com"), nil)
        XCTAssertEqual(blocklist("https://admeld.com/popup"), .advertising)
        XCTAssertEqual(blocklist("https://sub.admeld.com"), nil)
        XCTAssertEqual(blocklist("https://subadmeld.com"), nil)

        XCTAssertEqual(blocklist("https://aolanswers.com"), .content)
        XCTAssertEqual(blocklist("https://sub.aolanswers.com"), .content)
        XCTAssertEqual(blocklist("https://aolanswers.com/track"), .content)
        XCTAssertEqual(blocklist("https://aol.com.aolanswers.com"), .content)
        XCTAssertEqual(blocklist("https://aol.com.aolanswers.com", ["ers.com"]), nil)
        XCTAssertEqual(blocklist("https://games.com.aolanswers.com"), .content)
        XCTAssertEqual(blocklist("https://bluesky.com.aolanswers.com"), .content)

        XCTAssertEqual(blocklist("https://sub.xiti.com/track"), .analytics)
        XCTAssertEqual(blocklist("https://backtype.com"), .social)
        XCTAssertEqual(blocklist("https://backtype.com", [".firefox.com", "e.com"]), nil)
    }
}
