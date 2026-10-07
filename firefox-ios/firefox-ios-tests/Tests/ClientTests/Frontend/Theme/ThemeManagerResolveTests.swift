// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class ThemeManagerResolveTests: XCTestCase {
    private var mockThemeManager: MockThemeManager!

    override func setUp() async throws {
        try await super.setUp()
        mockThemeManager = MockThemeManager()
    }

    override func tearDown() async throws {
        mockThemeManager = nil
        try await super.tearDown()
    }

    // MARK: - privateOverride

    func testResolveTheme_withoutOverride_usesWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID, privateOverride: nil)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 0)
    }

    func testResolveTheme_forcingPrivateTheme_ignoresWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID, privateOverride: true)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }

    func testResolveTheme_forcingRegularTheme_ignoresWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID, privateOverride: false)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }

    // MARK: - shouldUsePrivateOverride / shouldBeInPrivateTheme

    func testResolveTheme_withDisabledOverride_usesWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID,
                                          shouldUsePrivateOverride: false,
                                          shouldBeInPrivateTheme: true)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 1)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 0)
    }

    func testResolveTheme_withEnabledOverride_forcingPrivateTheme_ignoresWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID,
                                          shouldUsePrivateOverride: true,
                                          shouldBeInPrivateTheme: true)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }

    func testResolveTheme_withEnabledOverride_forcingRegularTheme_ignoresWindowTheme() {
        _ = mockThemeManager.resolveTheme(for: .XCTestDefaultUUID,
                                          shouldUsePrivateOverride: true,
                                          shouldBeInPrivateTheme: false)

        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0)
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1)
    }
}
