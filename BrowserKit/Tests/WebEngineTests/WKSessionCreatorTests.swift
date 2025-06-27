// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Common
@testable import WebEngine

final class WKSessionCreatorTests: XCTestCase {
    @MainActor
    func testCreatePopupSession_callsClosureWithValidSession() {
        let subject = createSubject()
        let expectation = expectation(description: "wait for session to be created")

        subject.onNewSessionCreated = { session in
            expectation.fulfill()
        }
        let config = WKWebViewConfiguration()
        _ = subject.createPopupSession(configuration: config, parent: WKWebView(frame: .zero, configuration: config))

        wait(for: [expectation])
    }

    func createSubject() -> WKSessionCreator {
        let subject = WKSessionCreator(dependencies: .empty())
        trackForMemoryLeaks(subject)
        return subject
    }
}
