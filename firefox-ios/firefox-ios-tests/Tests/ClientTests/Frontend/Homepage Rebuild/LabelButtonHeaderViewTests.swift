// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

final class LabelButtonHeaderViewTests: XCTestCase {
    var view: LabelButtonHeaderView!
    let theme = DarkTheme()
    let sectionHeaderState = SectionHeaderState()

    override func setUp() {
        super.setUp()
        view = LabelButtonHeaderView()
    }

    override func tearDown() {
        view = nil
        super.tearDown()
    }

    func test_configure_withStateColor_appliesStateColorOverThemeColors() {
        view.configure(state: sectionHeaderState, textColor: .systemPink, theme: theme)

        XCTAssertEqual(view.titleLabel.textColor, .systemPink)
        XCTAssertEqual(view.moreButton.foregroundColorNormal, .systemPink)
    }

    func test_configure_withNoStateColro_appliesThemeColors() {
        let sectionHeaderState = SectionHeaderState()

        view.configure(state: sectionHeaderState, textColor: nil, theme: theme)

        XCTAssertEqual(view.titleLabel.textColor, theme.colors.textPrimary)
        XCTAssertEqual(view.moreButton.foregroundColorNormal, theme.colors.textAccent)
    }
}
