// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
import Common
import Shared
import Localizations
@testable import Client

final class TermsOfUseViewModelTests: XCTestCase {
    var termsOfUseManager: TermsOfUseManager!

    override func setUp() {
        super.setUp()
        termsOfUseManager = TermsOfUseManager()
    }

    override func tearDown() {
        termsOfUseManager = nil
        super.tearDown()
    }

    func test_combinedTextContainsDescriptionAndReview() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)
        XCTAssertTrue(viewModel.combinedText.contains(viewModel.descriptionText))
        XCTAssertTrue(viewModel.combinedText.contains(viewModel.reviewAndAcceptText))
    }

    func test_linkTermsIncludesExpectedLabels() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)
        let terms = viewModel.linkTerms

        XCTAssertTrue(terms.contains(String.localizedStringWithFormat(
            TermsOfUse.LinkTermsOfUse,
            AppName.shortName.rawValue
        )))
        XCTAssertTrue(terms.contains(TermsOfUse.LinkPrivacyNotice))
        XCTAssertTrue(terms.contains(TermsOfUse.LinkLearnMore))
    }

    func test_linkURLReturnsCorrectURLs() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)

        let termsOfUseURL = viewModel.linkURL(for: String.localizedStringWithFormat(
            TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue))
        XCTAssertTrue(termsOfUseURL?.absoluteString.contains("mozilla.org/about/legal/terms") ?? false)

        let privacyURL = viewModel.linkURL(for: TermsOfUse.LinkPrivacyNotice)
        XCTAssertTrue(privacyURL?.absoluteString.contains("mozilla.org/privacy/firefox") ?? false)

        let learnMoreURL = viewModel.linkURL(for: TermsOfUse.LinkLearnMore)
        XCTAssertTrue(learnMoreURL?.absoluteString.contains("support.mozilla.org") ?? false)
    }

    func test_markToUAppearedSetsFlag() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)
        XCTAssertFalse(termsOfUseManager.didShowThisLaunch)
        viewModel.markToUAppeared()
        XCTAssertTrue(termsOfUseManager.didShowThisLaunch)
    }

    func test_onAcceptCallsManager() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)
        termsOfUseManager.markDismissed()
        XCTAssertFalse(termsOfUseManager.hasAccepted)
        viewModel.onAccept?()
        XCTAssertTrue(termsOfUseManager.hasAccepted)
    }

    func test_onNotNowCallsManager() {
        let viewModel = TermsOfUseViewModel(termsOfUseManager: termsOfUseManager)
        termsOfUseManager.markAccepted()
        XCTAssertFalse(termsOfUseManager.wasDismissed)
        viewModel.onNotNow?()
        XCTAssertTrue(termsOfUseManager.wasDismissed)
    }
}
