/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Shared
import Storage

class FaviconFetcherTests: ProfileTest {
    let prefs = NSUserDefaultsPrefs(prefix: "PrefsTests")
    var lines = [String]()

    override func setUp() {
        prefs.clearAll()
    }

    func testTopSites() {
        withTestProfile { (profile) -> Void in
            var err: NSError? = nil
            let path = NSBundle(forClass: FaviconFetcherTests.self).pathForResource("topsites", ofType: "txt")!
            let data = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &err) as! String
            self.lines = split(data) { $0 == "\n" }
            let expectation = self.expectationWithDescription("Foo")
            self.foo(profile, callback: { expectation.fulfill() })

            self.waitForExpectationsWithTimeout(1000, handler: nil)
        }
    }

    func foo(profile: Profile, callback: (() -> Void)) {
        let line = lines.removeLast()
        let url = NSURL(string: "http://www.\(line)")!
        // println("Testing \(url)")
        FaviconFetcher.getForUrl(url, profile: profile) >>== { icons in
            println("Found icon for \(url) \(icons[0].url) \(icons[0].width)")

            if self.lines.count > 0 {
                self.foo(profile, callback: callback)
            } else {
                callback()
            }
        }
    }
}
