// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class PasswordGeneratorTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
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
