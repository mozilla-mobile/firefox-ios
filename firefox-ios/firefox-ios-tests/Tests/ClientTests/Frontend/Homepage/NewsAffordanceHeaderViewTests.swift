// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

@MainActor
final class NewsAffordanceHeaderViewTests: XCTestCase {
    private let darkTheme = DarkTheme()

    func test_configure_appliesThemeActionPrimaryToIconAndLabelColors() {
        let view = createSubject()

        view.configure(theme: darkTheme)

        let labels = allSubviews(in: view).compactMap { $0 as? UILabel }
        let imageViews = allSubviews(in: view).compactMap { $0 as? UIImageView }

        XCTAssertEqual(labels.count, 1)
        XCTAssertEqual(labels.first?.textColor, darkTheme.colors.actionPrimary)
        XCTAssertEqual(imageViews.count, 2)
        XCTAssertTrue(imageViews.allSatisfy { $0.tintColor == darkTheme.colors.actionPrimary })
    }

    private func createSubject() -> NewsAffordanceHeaderView {
        let subject = NewsAffordanceHeaderView()
        trackForMemoryLeaks(subject)
        return subject
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { subview in
            allSubviews(in: subview)
        }
    }
}
