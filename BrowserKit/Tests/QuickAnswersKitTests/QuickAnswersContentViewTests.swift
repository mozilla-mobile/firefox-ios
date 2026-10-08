// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Testing
import TestKit

@testable import QuickAnswersKit

@MainActor
final class PrivacyTapSpy {
    var callCount = 0
}

@Suite
@MainActor
struct QuickAnswersContentViewTests {
    let testHelper = SwiftTestingHelper()
    let privacyTapSpy = PrivacyTapSpy()

    @Test
    @available(iOS 17.0, *)
    func test_privacyLinkTap_notifiesOnce() {
        let subject = createSubject()

        (subject.privacyTipSourceView as? UIControl)?.sendActions(for: .touchUpInside)

        #expect(privacyTapSpy.callCount == 1)
    }

    // MARK: - Helper
    @available(iOS 17.0, *)
    private func createSubject() -> QuickAnswersContentView {
        let subject = QuickAnswersContentView()
        subject.configureStrings(QuickAnswersViewConfiguration.mock.contentView)
        subject.configurePrivacyLink { [privacyTapSpy] in privacyTapSpy.callCount += 1 }
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
