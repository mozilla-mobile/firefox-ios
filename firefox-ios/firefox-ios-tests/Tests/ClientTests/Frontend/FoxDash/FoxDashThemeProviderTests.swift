// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class FoxDashThemeProviderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        FxNimbus.shared.features.foxDashFeature.with { _ in FoxDashFeature() }
    }

    override func tearDown() async throws {
        FxNimbus.shared.features.foxDashFeature.with { _ in FoxDashFeature() }
        try await super.tearDown()
    }

    func test_themeID_defaultConfiguration_returnsNormal() {
        let subject = createSubject()

        XCTAssertEqual(subject.themeID, "normal")
    }

    func test_themeID_christmasConfigured_returnsChristmas() {
        FxNimbus.shared.features.foxDashFeature.with { _ in FoxDashFeature(theme: .christmas) }
        let subject = createSubject()

        XCTAssertEqual(subject.themeID, "christmas")
    }

    private func createSubject() -> FoxDashThemeProvider {
        return FoxDashThemeProvider()
    }
}
