// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import XCTest

@testable import Client

@MainActor
final class GenericSelectableItemCellViewTests: XCTestCase {
    private let theme = LightTheme()

    func testColorsUseTheTheme() {
        let subject = createSubject(isSelected: true)

        XCTAssertEqual(subject.textColor, Color(theme.colors.textPrimary))
        XCTAssertEqual(subject.checkmarkTintColor, Color(theme.colors.iconAccent))
        XCTAssertEqual(subject.backgroundColor, Color(theme.colors.layer5))
    }

    func testColorsFallBackToClearWithoutATheme() {
        let subject = createSubject(isSelected: true, theme: nil)

        XCTAssertEqual(subject.textColor, Color(UIColor.clear))
        XCTAssertEqual(subject.checkmarkTintColor, Color(UIColor.clear))
        XCTAssertEqual(subject.backgroundColor, Color(UIColor.clear))
    }

    func testOnTapIsForwarded() {
        var tapCount = 0
        let subject = createSubject(isSelected: false) { tapCount += 1 }

        subject.onTap()

        XCTAssertEqual(tapCount, 1)
    }

    func testRendersWhenSelected() {
        let subject = createSubject(isSelected: true)

        XCTAssertNotNil(render(subject))
    }

    func testRendersWhenNotSelected() {
        let subject = createSubject(isSelected: false)

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

    private func createSubject(isSelected: Bool,
                               theme: Theme? = LightTheme(),
                               onTap: @escaping () -> Void = {}) -> GenericSelectableItemCellView {
        return GenericSelectableItemCellView(title: "Home",
                                             isSelected: isSelected,
                                             theme: theme,
                                             a11yIdentifier: "HomeButton",
                                             onTap: onTap)
    }
}
