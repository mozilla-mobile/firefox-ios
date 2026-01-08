// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class PasswordGeneratorViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testPasswordGeneratorViewController_simpleCreation_hasNoLeaks() {
        let mockProfile = MockProfile()
        let currentTab = Tab(profile: mockProfile, windowUUID: windowUUID)
        let URL = URL(string: "https://foo.com")!
        let webView = MockWKWebView(URL)
        let frameContext = PasswordGeneratorFrameContext(origin: "https://foo.com",
                                                         host: "foo.com",
                                                         webView: webView)
        let passwordGeneratorViewController = PasswordGeneratorViewController(windowUUID: windowUUID,
                                                                              currentTab: currentTab,
                                                                              frameContext: frameContext)
        trackForMemoryLeaks(passwordGeneratorViewController)
    }
}
