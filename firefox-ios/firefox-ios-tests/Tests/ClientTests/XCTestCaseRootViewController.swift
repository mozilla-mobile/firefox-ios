// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class XCTestCaseRootViewController: XCTestCase {
    var rootViewController: UIViewController!
    var window: UIWindow!

    override func setUp() {
        super.setUp()
        rootViewController = UIViewController()
        window = UIWindow()
    }

    override func tearDown() {
        rootViewController = nil
        window = nil
        super.tearDown()
    }

    func loadViewForTesting() {
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        rootViewController.view.layoutIfNeeded()
    }
}
