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
    private var privacyWindowBuildCount = 0

    private func makeManager(
        privacyWindowFactory: @escaping () -> UIWindow? = { UIWindow() }
    ) -> PrivacyProtectionWindowManager {
        PrivacyProtectionWindowManager(
            privacyWindowFactory: { [unowned self] in
                privacyWindowBuildCount += 1
                return privacyWindowFactory()
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

    func testShowLeavesMainWindowKey() throws {
        // Regression for FXIOS-17309: the overlay must not take key status, otherwise
        // the keyboard session on the main window is torn down while it is covered.
        // Only a window attached to a scene can become key, so borrow the host app's.
        let windowScene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousKeyWindow = windowScene.keyWindow
        let mainWindow = UIWindow(windowScene: windowScene)
        mainWindow.makeKeyAndVisible()
        defer {
            mainWindow.isHidden = true
            previousKeyWindow?.makeKey()
        }
        let manager = makeManager(privacyWindowFactory: { UIWindow(windowScene: windowScene) })

        manager.show()
        defer { manager.hide() }

        XCTAssertTrue(mainWindow.isKeyWindow)
        XCTAssertFalse(manager.privacyWindow?.isKeyWindow ?? true)
    }

    func testShowIsNoOpWhenNoWindowSceneAvailable() {
        let manager = makeManager(privacyWindowFactory: { nil })

        manager.show()

        XCTAssertNil(manager.privacyWindow)
    }
}
