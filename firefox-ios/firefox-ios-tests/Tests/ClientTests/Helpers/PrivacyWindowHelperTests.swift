// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class PrivacyWindowHelperTests: XCTestCase {
    func test_showWindow_withNilScene_doesNotCreatePrivacyWindow() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let windowsBefore = windowScene.windows
        let subject = createSubject()

        subject.showWindow(windowScene: nil, withThemedColor: .red)

        XCTAssertEqual(windowScene.windows.count, windowsBefore.count)
        XCTAssertNil(privacyWindow(in: windowScene))
    }

    func test_showWindow_withValidScene_addsPrivacyWindowToScene() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red)

        XCTAssertNotNil(privacyWindow(in: windowScene))
    }

    func test_showWindow_setsRootViewBackgroundColorToProvidedColor() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let expectedColor = UIColor.systemPink
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: expectedColor)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        XCTAssertEqual(window.rootViewController?.view.backgroundColor, expectedColor)
    }

    func test_showWindow_setsWindowLevelAboveAlert() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        XCTAssertEqual(window.windowLevel, .alert + 1)
    }

    func test_showWindow_doesNotHideWindow() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        XCTAssertFalse(window.isHidden)
    }

    func test_showWindow_withDefaultShowLogo_doesNotAddLogoSubview() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        let rootView = try XCTUnwrap(window.rootViewController?.view)
        XCTAssertTrue(rootView.subviews.isEmpty)
    }

    func test_showWindow_withShowLogoFalse_doesNotAddLogoSubview() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red, showLogo: false)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        let rootView = try XCTUnwrap(window.rootViewController?.view)
        XCTAssertTrue(rootView.subviews.isEmpty)
    }

    func test_showWindow_withShowLogoTrue_addsLogoImageView() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()

        subject.showWindow(windowScene: windowScene, withThemedColor: .red, showLogo: true)

        let window = try XCTUnwrap(privacyWindow(in: windowScene))
        let rootView = try XCTUnwrap(window.rootViewController?.view)
        let imageViews = rootView.subviews.compactMap { $0 as? UIImageView }
        XCTAssertEqual(imageViews.count, 1)
    }

    func test_removeWindow_afterShowWindow_hidesPrivacyWindow() throws {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let subject = createSubject()
        subject.showWindow(windowScene: windowScene, withThemedColor: .red)
        let window = try XCTUnwrap(privacyWindow(in: windowScene))

        subject.removeWindow()

        XCTAssertTrue(window.isHidden)
    }

    func test_removeWindow_withoutPriorShow_doesNotCrash() {
        let subject = createSubject()

        subject.removeWindow()
    }

    // MARK: - Helpers

    private func createSubject() -> PrivacyWindowHelper {
        let subject = PrivacyWindowHelper()
        addTeardownBlock { @MainActor in
            subject.removeWindow()
        }
        return subject
    }

    /// Finds the privacy window in the scene by its distinguishing windowLevel (.alert + 1).
    private func privacyWindow(in scene: UIWindowScene) -> UIWindow? {
        return scene.windows.first { $0.windowLevel == .alert + 1 }
    }
}
