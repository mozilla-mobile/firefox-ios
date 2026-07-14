// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class SwipeGestureFeatureFlagProviderTests: XCTestCase {
    private var mockFlags: MockNimbusFeatureFlags!

    override func setUp() {
        mockFlags = MockNimbusFeatureFlags()
        super.setUp()
    }

    override func tearDown() {
        mockFlags = nil
        super.tearDown()
    }

    func createSubject() -> SwipeGestureFeatureFlagProvider {
        let subject = SwipeGestureFeatureFlagProvider(featureFlagsProvider: mockFlags)
        return subject
    }

    // MARK: - isInteractiveGestureEnabled

    func testIsInteractiveGestureEnabled_interactiveOnly_returnsTrue() {
        let subject = createSubject()
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]

        XCTAssertTrue(subject.isInteractiveGestureEnabled)
    }

    func testIsInteractiveGestureEnabled_swipeOverridesInteractive_returnsFalse() {
        let subject = createSubject()
        mockFlags.enabledFlags = [
            .addressBarGestureToOpenTabTrayInteractive,
            .addressBarGestureToOpenTabTraySwipe
        ]

        XCTAssertFalse(subject.isInteractiveGestureEnabled)
    }

    func testIsInteractiveGestureEnabled_interactiveDisabled_returnsFalse() {
        let subject = createSubject()
        mockFlags.enabledFlags = []

        XCTAssertFalse(subject.isInteractiveGestureEnabled)
    }

    // MARK: - isSwipeGestureEnabled

    func testIsSwipeGestureEnabled_reflectsFlag() {
        let subject = createSubject()
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTraySwipe]

        XCTAssertTrue(subject.isSwipeGestureEnabled)
    }

    // MARK: - isCloseTabEnabled

    func testIsCloseTabEnabled_reflectsFlag() {
        let subject = createSubject()
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayCloseTab]

        XCTAssertTrue(subject.isCloseTabEnabled)
    }

    // MARK: - isAnyGestureEnabled

    func testIsAnyGestureEnabled_interactiveOnly_returnsTrue() {
        let subject = createSubject()
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]

        XCTAssertTrue(subject.isAnyGestureEnabled)
    }

    func testIsAnyGestureEnabled_swipeOnly_returnsTrue() {
        let subject = createSubject()
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTraySwipe]

        XCTAssertTrue(subject.isAnyGestureEnabled)
    }

    func testIsAnyGestureEnabled_noGestures_returnsFalse() {
        let subject = createSubject()
        mockFlags.enabledFlags = []

        XCTAssertFalse(subject.isAnyGestureEnabled)
    }
}
