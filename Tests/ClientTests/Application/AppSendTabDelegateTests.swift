// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class AppSendTabDelegateTests: XCTestCase {
    private var applicationHelper: MockApplicationHelper!

    override func setUp() {
        super.setUp()
        self.applicationHelper = MockApplicationHelper()
    }

    override func tearDown() {
        super.tearDown()
        self.applicationHelper = nil
    }

    func testOpenSendTabs() {
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url])

        XCTAssertEqual(applicationHelper.openURLCalled, 1)
        let expectedURL = URL(string: URL.mozInternalScheme + "://open-url?url=\(url)")!
        XCTAssertEqual(applicationHelper.lastOpenURL, expectedURL)
    }

    func testOpenSendTabs_multipleURLs() {
        let url = URL(string: "https://mozilla.com", invalidCharacters: false)!
        let subject = createSubject()
        subject.openSendTabs(for: [url, url, url])

        XCTAssertEqual(applicationHelper.openURLCalled, 3)
    }

    // MARK: - Helper

    func createSubject() -> AppSendTabDelegate {
        let subject = AppSendTabDelegate(app: UIApplication.shared,
                                         applicationHelper: applicationHelper,
                                         mainQueue: MockDispatchQueue())
        trackForMemoryLeaks(subject)
        return subject
    }
}
