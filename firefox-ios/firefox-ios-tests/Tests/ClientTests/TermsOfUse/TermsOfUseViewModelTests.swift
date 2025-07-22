// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
import Common
import Shared
import Localizations
@testable import Client

class TermsOfUseViewModelTests: XCTestCase {
        func test_combinedTextContainsDescriptionAndReview() {
            let vm = TermsOfUseViewModel()
            XCTAssertTrue(vm.combinedText.contains(vm.descriptionText))
            XCTAssertTrue(vm.combinedText.contains(vm.reviewAndAcceptText))
        }

        func test_linkTermsIncludesExpectedLabels() {
            let vm = TermsOfUseViewModel()
            let terms = vm.linkTerms
            XCTAssertTrue(terms.contains(String.localizedStringWithFormat(
                TermsOfUse.LinkTermsOfUse,
                AppName.shortName.rawValue)))
            XCTAssertTrue(terms.contains(TermsOfUse.LinkPrivacyNotice))
            XCTAssertTrue(terms.contains(TermsOfUse.LinkLearnMore))
        }

        func test_linkURLReturnsCorrectURLs() {
            let vm = TermsOfUseViewModel()

            let termsOfUseURL = vm.linkURL(for: String.localizedStringWithFormat(
                TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue))
            XCTAssertTrue(termsOfUseURL?.absoluteString.contains("mozilla.org/about/legal/terms") ?? false)

            let privacyURL = vm.linkURL(for: TermsOfUse.LinkPrivacyNotice)
            XCTAssertTrue(privacyURL?.absoluteString.contains("mozilla.org/privacy/firefox") ?? false)

            let learnMoreURL = vm.linkURL(for: TermsOfUse.LinkLearnMore)
            XCTAssertTrue(learnMoreURL?.absoluteString.contains("support.mozilla.org") ?? false)
        }
}
