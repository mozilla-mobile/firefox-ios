// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
class XCTestCaseRootViewController: XCTestCase {
    var rootViewController: UIViewController!
    var window: UIWindow!

    override func setUp() async throws {
        try await super.setUp()
        rootViewController = UIViewController()
        window = UIWindow()
    }

    override func tearDown() async throws {
        rootViewController = nil
        window = nil
        try await super.tearDown()
    }

    func loadViewForTesting() {
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        rootViewController.view.layoutIfNeeded()
    }
}
