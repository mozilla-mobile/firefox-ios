// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class RestoreTabManagerTestsTests: XCTestCase {
    private var delegate: MockRestoreTabManagerDelegate?

    override func setUp() {
        super.setUp()
        delegate = MockRestoreTabManagerDelegate()
    }

    override func tearDown() {
        super.tearDown()
        delegate = nil
    }

    // TODO: Laurie

    func createSubject(hasTabsToRestoreAtStartup: Bool) -> RestoreTabManager {
        let subject = DefaultRestoreTabManager(hasTabsToRestoreAtStartup: hasTabsToRestoreAtStartup,
                                               delegate: delegate)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - MockRestoreTabManagerDelegate
class MockRestoreTabManagerDelegate: RestoreTabManagerDelegate {
    var needsTabRestoreCalled = 0
    var needsNewTabOpenedCalled = 0

    func needsTabRestore() {
        needsTabRestoreCalled += 1
    }

    func needsNewTabOpened() {
        needsNewTabOpenedCalled += 1
    }
}
