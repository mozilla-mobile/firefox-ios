// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/* TODO: Ecosia check if still neeeded as now the fetcher seems either not used or is somehow using the SiteImageView's BundleDomainBuilder
import XCTest
@testable import SiteImageView
@testable import Ecosia

final class BundleImageFetcherTests: XCTestCase {

    var urlProvider: URLProvider = .staging

    func testFinancialReportsURLs() {

        let def = Language.current
        Language.current = .en
        EcosiaURLProvider.Language.current = .en
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.absoluteString, EcosiaURLProvider.financialReportsURL.absoluteString)

        Language.current = .fr
        EcosiaURLProvider.Language.current = .fr
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.absoluteString, EcosiaURLProvider.financialReportsURL.absoluteString)

        Language.current = .de
        EcosiaURLProvider.Language.current = .de
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.absoluteString, EcosiaURLProvider.financialReportsURL.absoluteString)
    }

    func testPrivacyURLs() {
        XCTAssertNotNil(urlProvider.privacy)
        XCTAssertEqual(urlProvider.privacy.absoluteString, EcosiaURLProvider.privacyURL.absoluteString)
    }
}
 */
