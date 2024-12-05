// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class TabLocationViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        AppContainer.shared.reset()
    }

    func testDelegateMemoryLeak() {
        let tabLocationView = TabLocationView(windowUUID: .XCTestDefaultUUID)
        let delegate = MockTabLocationViewDelegate()
        tabLocationView.delegate = delegate
        trackForMemoryLeaks(tabLocationView)
    }
}

// A mock delegate
class MockTabLocationViewDelegate: TabLocationViewDelegate {
    func tabLocationViewPresentCFR(at sourceView: UIView) {}
    func tabLocationViewDidTapLocation(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidLongPressLocation(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidTapReaderMode(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidTapReload(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidTapShield(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidBeginDragInteraction(_ tabLocationView: TabLocationView) {}
    func tabLocationViewDidLongPressReaderMode(_ tabLocationView: TabLocationView) -> Bool {
        return false
    }
    func tabLocationViewDidLongPressReload(_ tabLocationView: TabLocationView) {}
    func tabLocationViewLocationAccessibilityActions(
        _ tabLocationView: TabLocationView
    ) -> [UIAccessibilityCustomAction]? {
        return nil
    }
}
