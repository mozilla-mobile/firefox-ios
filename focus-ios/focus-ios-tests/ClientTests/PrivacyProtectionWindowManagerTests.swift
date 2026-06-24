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

    func testShowRevealsOverlayAboveAlertLevel() {
        let manager = makeManager()

        manager.show()

        XCTAssertNotNil(manager.privacyWindow)
        XCTAssertFalse(manager.privacyWindow?.isHidden ?? true)
        XCTAssertEqual(manager.privacyWindow?.windowLevel, .alert + 1)
    }

    func testReusedOverlayIsUnhiddenOnNextShow() {
        // Regression for FXIOS-16007: hide must keep the window alive and the next
        // show must reuse it rather than rebuild a not-yet-rendered one.
        let manager = makeManager()
        manager.show()
        let firstWindow = manager.privacyWindow

        manager.hide()
        XCTAssertTrue(firstWindow?.isHidden ?? false)

        manager.show()

        XCTAssertTrue(manager.privacyWindow === firstWindow)
        XCTAssertEqual(privacyWindowBuildCount, 1)
        XCTAssertFalse(firstWindow?.isHidden ?? true)
    }

    func testHideRestoresMainWindow() {
        let manager = makeManager()
        manager.show()

        manager.hide()

        XCTAssertEqual(mainWindowRestoreCount, 1)
    }

    func testShowIsNoOpWhenNoWindowSceneAvailable() {
        let manager = makeManager(privacyWindowFactory: { nil })

        manager.show()

        XCTAssertNil(manager.privacyWindow)
    }
}
