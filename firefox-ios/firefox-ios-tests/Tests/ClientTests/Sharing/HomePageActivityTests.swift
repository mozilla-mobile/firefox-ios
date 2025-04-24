// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
@testable import Client

final class HomePageActivityTests: XCTestCase {
    func testInit_withOnlineURL_returnsSameURL() {
        let urlString = "https://www.google.com"
        let url = URL(string: urlString)!
        let title = "test title"
        let subject = createSubject(url: url, title: title)

        XCTAssertEqual(subject.url, url)
        XCTAssertEqual(subject.title, title)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testInit_withLocalURL_returnsNilURL() {
        let urlString = "internal://fennec.test"
        let url = URL(string: urlString)!
        let subject = createSubject(url: url)

        // has to be nil since we try only to unwrap the url param from internal url
        XCTAssertNil(subject.url)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testInit_withLocalHostURL_returnsUnwrappedURLParameter() {
        let innerUrl = "https//:www.google.com"
        let urlString = "http://localhost:\(AppInfo.webserverPort)/?url=\(innerUrl)"
        let url = URL(string: urlString)!
        let subject = createSubject(url: url)

        XCTAssertEqual(subject.url, URL(string: innerUrl))
        // needed to fully deallocate the WKWebView
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    private func createSubject(url: URL? = nil,
                               title: String? = nil) -> HomePageActivity {
        let subject = HomePageActivity(url: url, title: title)
        trackForMemoryLeaks(subject)
        return subject
    }
}
