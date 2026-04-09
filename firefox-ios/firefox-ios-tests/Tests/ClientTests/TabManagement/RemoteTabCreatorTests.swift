// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Storage
import XCTest

@MainActor
final class RemoteTabCreatorTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testGivenTabIsPrivate_thenReturnNil() {
        let tab = Tab(profile: MockProfile(),
                      isPrivate: true,
                      windowUUID: .XCTestDefaultUUID)
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNil(result)
    }

    func testGivenTabHasNoURL_thenReturnNil() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: .XCTestDefaultUUID)
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNil(result)
    }

    func testGivenTabIsInternalURL_thenReturnsNil() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "internal://local/about/home")
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNil(result)
    }

    func testGivenTabIsJavascriptURL_thenReturnsNil() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "javascript:thisisaURL.com")
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNil(result)
    }

    func testGivenTabHasNilHost_thenReturnsNil() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "api/v1/users")
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNil(result)
    }

    func testGivenTabHasProperURL_thenReturnsRemoteTab() {
        let tab = Tab(profile: MockProfile(),
                      windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "https://thisisaURL.com")
        let result = RemoteTabCreator.toRemoteTab(from: tab)
        XCTAssertNotNil(result)
    }
}
