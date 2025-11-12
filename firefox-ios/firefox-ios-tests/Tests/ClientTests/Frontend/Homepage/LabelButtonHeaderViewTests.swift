// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class LabelButtonHeaderViewTests: XCTestCase {
    let theme = DarkTheme()
    let sectionHeaderState = SectionHeaderConfiguration(title: "test title", a11yIdentifier: "test a11y identifier")

    func test_configure_withStateColor_appliesStateColorOverThemeColors() {
        let view = createSubject()
        view.configure(state: sectionHeaderState, textColor: .systemPink, theme: theme)

        XCTAssertEqual(view.titleLabel.textColor, .systemPink)
        XCTAssertEqual(view.moreButton.foregroundColorNormal, .systemPink)
    }

    func test_configure_withNoStateColor_appliesThemeColors() {
        let view = createSubject()
        view.configure(state: sectionHeaderState, textColor: nil, theme: theme)

        XCTAssertEqual(view.titleLabel.textColor, theme.colors.textPrimary)
        XCTAssertEqual(view.moreButton.foregroundColorNormal, theme.colors.textAccent)
    }

    private func createSubject() -> LabelButtonHeaderView {
        let view = LabelButtonHeaderView()
        trackForMemoryLeaks(view)
        return view
    }
}
