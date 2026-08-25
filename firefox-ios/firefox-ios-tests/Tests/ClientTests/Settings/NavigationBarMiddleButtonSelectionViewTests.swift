// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import XCTest

@testable import Client

@MainActor
final class NavigationBarMiddleButtonSelectionViewTests: XCTestCase {
    func testIdentifierNameMatchesTheSelectedOption() {
        let subject = createSubject(selectedMiddleButton: .newTab)

        XCTAssertEqual(subject.identifierName(for: .home),
                       AccessibilityIdentifiers.Settings.NavigationToolbar.homeButton)
        XCTAssertEqual(subject.identifierName(for: .newTab),
                       AccessibilityIdentifiers.Settings.NavigationToolbar.newTabButton)
    }

    func testBackgroundColorFallsBackToClearWithoutATheme() {
        let subject = createSubject(selectedMiddleButton: .home, theme: nil)

        XCTAssertEqual(subject.backgroundColor, Color(UIColor.clear))
    }

    func testRendersWithNewTabSelected() {
        let subject = createSubject(selectedMiddleButton: .newTab)

        XCTAssertNotNil(render(subject))
    }

    func testRendersWithHomeSelected() {
        let subject = createSubject(selectedMiddleButton: .home)

        XCTAssertNotNil(render(subject))
    }

    /// Lays the view out inside a window so that its body is evaluated.
    private func render(_ view: some View) -> UIView {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        return host.view
    }

    private func createSubject(selectedMiddleButton: NavigationBarMiddleButtonType,
                               theme: Theme? = LightTheme(),
                               onSelected: ((NavigationBarMiddleButtonType) -> Void)? = nil)
    -> NavigationBarMiddleButtonSelectionView {
        return NavigationBarMiddleButtonSelectionView(theme: theme,
                                                      selectedMiddleButton: selectedMiddleButton,
                                                      onSelected: onSelected)
    }
}
