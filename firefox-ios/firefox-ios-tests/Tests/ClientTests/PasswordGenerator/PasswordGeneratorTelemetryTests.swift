// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class PasswordGeneratorTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        gleanWrapper = MockGleanWrapper()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        gleanWrapper = nil
        try await super.tearDown()
    }

    func testShowPasswordGeneratorDialog() {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.passwordGeneratorDialogShown()
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testUsePasswordButtonPressed() {
        let subject = createSubject(gleanWrapper: gleanWrapper)
        subject.usePasswordButtonPressed()
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    private func createSubject(gleanWrapper: GleanWrapper) -> PasswordGeneratorTelemetry {
        PasswordGeneratorTelemetry(gleanWrapper: gleanWrapper)
    }
}
