// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class PasswordManagerCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!

    override func setUp() {
        super.setUp()
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
    }

    // MARK: - Helper
    func createSubject() -> PasswordManagerCoordinator {
        let subject = PasswordManagerCoordinator(router: mockRouter)
        trackForMemoryLeaks(subject)
        return subject
    }
}
