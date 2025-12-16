// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class URLProviderTests: XCTestCase {

    var urlProvider: URLProvider = .staging

    func testFinancialReports() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "ecosia-financial-reports-tree-planting-receipts")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "rapports-financiers-recus-de-plantations-arbres")

        Language.current = .de
        XCTAssertNotNil(urlProvider.financialReports)
        XCTAssertEqual(urlProvider.financialReports.pathComponents.last, "ecosia-finanzberichte-baumplanzbelege")

        Language.current = def
    }

    func testBlog() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://blog.ecosia.org/")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://fr.blog.ecosia.org/")

        Language.current = .de
        XCTAssertNotNil(urlProvider.blog)
        XCTAssertEqual(urlProvider.blog.absoluteString, "https://de.blog.ecosia.org/")

        Language.current = def
    }

    func testTrees() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/where-does-ecosia-plant-trees/"))

        Language.current = .fr
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/projets/"))

        Language.current = .de
        XCTAssertNotNil(urlProvider.trees)
        XCTAssertTrue(urlProvider.trees.absoluteString.hasSuffix("tag/projekte/"))

        Language.current = def
    }

    func testBetaProgram() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/EeMLqL3X")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/oaFZzT0F")

        Language.current = .de
        XCTAssertNotNil(urlProvider.betaProgram)
        XCTAssertEqual(urlProvider.betaProgram.absoluteString, "https://ecosia.typeform.com/to/catmFLuA")

        Language.current = def
    }

    func testBetaFeedback() {
        let def = Language.current
        Language.current = .en
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/LlUGlFT9")

        Language.current = .fr
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/PRw7550n")

        Language.current = .de
        XCTAssertNotNil(urlProvider.betaFeedback)
        XCTAssertEqual(urlProvider.betaFeedback.absoluteString, "https://ecosia.typeform.com/to/pIQ3uwp9")

        Language.current = def
    }

    // MARK: - AI Search Tests

    func testAISearchWithoutOrigin() {
        let url = urlProvider.aiSearch(origin: nil)
        XCTAssertTrue(url.absoluteString.hasSuffix("/ai-search"))
        XCTAssertNil(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    }

    func testAISearchWithNTPOrigin() {
        let url = urlProvider.aiSearch(origin: .ntp)
        XCTAssertTrue(url.absoluteString.contains("/ai-search?origin=newtabbutton"))
    }

    func testAISearchWithAutocompleteOrigin() {
        let url = urlProvider.aiSearch(origin: .autocomplete)
        XCTAssertTrue(url.absoluteString.contains("/ai-search?origin=autocomplete_app"))
    }
}
