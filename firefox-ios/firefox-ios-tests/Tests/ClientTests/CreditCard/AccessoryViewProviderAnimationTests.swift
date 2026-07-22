// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class AccessoryViewProviderAnimationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testReloadDoesNotAnimateToolbarItemsOnIOS26() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("This regression only affects iOS 26 and later")
        }

        let toolbar = ToolbarSpy()
        let subject = AccessoryViewProvider(windowUUID: WindowUUID(), toolbar: toolbar)
        toolbar.reset()

        subject.reloadViewFor(.creditCard)

        XCTAssertEqual(toolbar.lastAnimatedValue, false)
    }
}

private final class ToolbarSpy: UIToolbar {
    private(set) var lastAnimatedValue: Bool?

    override func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        lastAnimatedValue = animated
        super.setItems(items, animated: animated)
    }

    func reset() {
        lastAnimatedValue = nil
    }
}
