// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class SwipeGestureFeatureFlagProviderTests: XCTestCase {
    private var mockFlags: MockNimbusFeatureFlags!
    private var subject: SwipeGestureFeatureFlagProvider!

    override func setUp() {
        super.setUp()
        // Inject the mock provider directly so tests avoid the AppContainer resolution.
        mockFlags = MockNimbusFeatureFlags()
        subject = SwipeGestureFeatureFlagProvider(featureFlagsProvider: mockFlags)
    }

    override func tearDown() {
        mockFlags = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - isInteractiveGestureEnabled

    func testIsInteractiveGestureEnabled_interactiveOnly_returnsTrue() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]

        XCTAssertTrue(subject.isInteractiveGestureEnabled)
    }

    func testIsInteractiveGestureEnabled_swipeOverridesInteractive_returnsFalse() {
        mockFlags.enabledFlags = [
            .addressBarGestureToOpenTabTrayInteractive,
            .addressBarGestureToOpenTabTraySwipe
        ]

        XCTAssertFalse(subject.isInteractiveGestureEnabled)
    }

    func testIsInteractiveGestureEnabled_interactiveDisabled_returnsFalse() {
        mockFlags.enabledFlags = []

        XCTAssertFalse(subject.isInteractiveGestureEnabled)
    }

    // MARK: - isSwipeGestureEnabled

    func testIsSwipeGestureEnabled_reflectsFlag() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTraySwipe]

        XCTAssertTrue(subject.isSwipeGestureEnabled)
    }

    // MARK: - isCloseTabEnabled

    func testIsCloseTabEnabled_reflectsFlag() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayCloseTab]

        XCTAssertTrue(subject.isCloseTabEnabled)
    }

    // MARK: - isAnyGestureEnabled

    func testIsAnyGestureEnabled_interactiveOnly_returnsTrue() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]

        XCTAssertTrue(subject.isAnyGestureEnabled)
    }

    func testIsAnyGestureEnabled_swipeOnly_returnsTrue() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTraySwipe]

        XCTAssertTrue(subject.isAnyGestureEnabled)
    }

    func testIsAnyGestureEnabled_noGestures_returnsFalse() {
        mockFlags.enabledFlags = []

        XCTAssertFalse(subject.isAnyGestureEnabled)
    }
}
