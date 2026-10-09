// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Testing
import TestKit
import TipKit

@testable import QuickAnswersKit

@Suite
@MainActor
struct QuickAnswersPrivacyTipPresenterTests {
    let testHelper = SwiftTestingHelper()
    let presenter = MockPresenter()
    let sourceView = UIView()

    // MARK: - present
    @Test
    @available(iOS 17.0, *)
    func test_present_presentsTipPopover() {
        let subject = createSubject()

        subject.present(from: sourceView, iconColor: .black)

        #expect(presenter.presentCallCount == 1)
        #expect(presenter.lastPresentedViewController is TipUIPopoverViewController)
    }

    @Test
    @available(iOS 17.0, *)
    func test_present_calledTwice_presentsEachTime() {
        let subject = createSubject()

        subject.present(from: sourceView, iconColor: .black)
        subject.present(from: sourceView, iconColor: .black)

        #expect(presenter.presentCallCount == 2)
    }

    // MARK: - Helpers
    private func createSubject() -> QuickAnswersPrivacyTipPresenter {
        let subject = QuickAnswersPrivacyTipPresenter(
            presenter: presenter,
            strings: QuickAnswersViewConfiguration.mock.privacyBanner
        )
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
