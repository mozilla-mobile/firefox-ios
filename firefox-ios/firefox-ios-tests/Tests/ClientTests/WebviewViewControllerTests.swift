// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import XCTest
import Glean

@testable import Client
// TODO: FXIOS-12158 Add back after investigating why video player is broken
// class WebviewViewControllerTests: XCTestCase {
//    var webview: WKWebViewMock!
//
//    override func setUp() {
//        super.setUp()
//
//        webview = WKWebViewMock( URL(string: "https://foo.com")!)
//    }
//
//    override func tearDown() {
//        webview = nil
//        super.tearDown()
//    }
//
//    func testEnteringFullScreenCall_FullScreenStateTrue() {
//        let subject = createSubject()
//        subject.enteringFullscreen()
//        XCTAssertTrue(subject.isFullScreen)
//        XCTAssertTrue(webview.translatesAutoresizingMaskIntoConstraints)
//    }
//
//    func testExitingFullScreenCall_FullScreenStateFalse() {
//        let subject = createSubject()
//        subject.exitingFullscreen()
//        XCTAssertFalse(subject.isFullScreen)
//        XCTAssertFalse(webview.translatesAutoresizingMaskIntoConstraints)
//    }
//
//    // MARK: Helper
//    private func createSubject() -> WebviewViewController {
//        let subject = WebviewViewController(webView: webview)
//        trackForMemoryLeaks(subject)
//
//        return subject
//    }
// }
