/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

final class PrivacyProtectionWindowManagerTests: XCTestCase {
    private var mainWindow: UIWindow!
    private var privacyWindowBuildCount = 0
    private var mainWindowRestoreCount = 0

    override func setUp() {
        super.setUp()
        mainWindow = UIWindow()
        privacyWindowBuildCount = 0
        mainWindowRestoreCount = 0
    }

    override func tearDown() {
        mainWindow = nil
        super.tearDown()
    }

    private func makeManager(
        privacyWindowFactory: @escaping () -> UIWindow? = { UIWindow() }
    ) -> PrivacyProtectionWindowManager {
        PrivacyProtectionWindowManager(
            privacyWindowFactory: { [unowned self] in
                privacyWindowBuildCount += 1
                return privacyWindowFactory()
            },
            mainWindowProvider: { [unowned self] in
                mainWindowRestoreCount += 1
                return mainWindow
            },
            rootViewControllerFactory: { UIViewController() }
        )
    }

    func testShowRevealsOverlay() {
        let manager = makeManager()

        manager.show()

        XCTAssertNotNil(manager.privacyWindow)
        XCTAssertFalse(manager.privacyWindow?.isHidden ?? true)
    }

    func testOverlayUsesWindowLevelAboveAlert() {
        let manager = makeManager()

        manager.show()

        XCTAssertEqual(manager.privacyWindow?.windowLevel, .alert + 1)
    }

    func testShowReusesSameWindowAndBuildsOnlyOnce() {
        let manager = makeManager()

        manager.show()
        let firstWindow = manager.privacyWindow
        manager.hide()
        manager.show()

        XCTAssertTrue(manager.privacyWindow === firstWindow)
        XCTAssertEqual(privacyWindowBuildCount, 1)
    }

    func testHideKeepsWindowAliveButHidden() {
        let manager = makeManager()
        manager.show()

        manager.hide()

        // Must survive: nil'ing it forced a not-yet-rendered rebuild on the next resign.
        XCTAssertNotNil(manager.privacyWindow)
        XCTAssertTrue(manager.privacyWindow?.isHidden ?? false)
    }

    func testReusedOverlayIsUnhiddenOnNextShow() {
        // Ticket sequence: lock, Face ID unlock, background ~2s later. The fix drops
        // `isHidden = false` and leans on makeKeyAndVisible() to un-hide the reused
        // window — pin that here. FXIOS-16007.
        let manager = makeManager()
        manager.show()
        let firstWindow = manager.privacyWindow
        manager.hide()
        XCTAssertTrue(firstWindow?.isHidden ?? false, "overlay should be hidden after unlock")

        manager.show()

        XCTAssertTrue(manager.privacyWindow === firstWindow, "must reuse, not rebuild")
        XCTAssertFalse(firstWindow?.isHidden ?? true, "reused overlay must be un-hidden on next show")
    }

    func testHideRestoresMainWindow() {
        let manager = makeManager()
        manager.show()

        manager.hide()

        // Hiding the overlay must hand key back to the main window.
        XCTAssertEqual(mainWindowRestoreCount, 1)
    }

    func testShowIsNoOpWhenNoWindowSceneAvailable() {
        let manager = makeManager(privacyWindowFactory: { nil })

        manager.show()

        XCTAssertNil(manager.privacyWindow)
    }
}
