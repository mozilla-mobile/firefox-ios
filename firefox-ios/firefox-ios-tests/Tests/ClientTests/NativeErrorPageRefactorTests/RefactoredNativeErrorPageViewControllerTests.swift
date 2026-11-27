// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class RefactoredNativeErrorPageViewControllerTests: XCTestCase {
    private let originalURL = URL(string: "https://example.com")!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testGenericPage_showsTitleAndDescription() throws {
        let subject = try createSubject(type: .generic)

        let title = try XCTUnwrap(label(AccessibilityIdentifiers.NativeErrorPage.titleLabel, in: subject.view))
        let description = try XCTUnwrap(label(AccessibilityIdentifiers.NativeErrorPage.errorDescriptionLabel,
                                              in: subject.view))
        XCTAssertEqual(title.text, .NativeErrorPage.Generic.TitleLabel)
        XCTAssertTrue(description.text?.contains("example.com") ?? false)
    }

    func testGenericPage_showsErrorCodeAndHidesAdvanced() throws {
        let subject = try createSubject(type: .generic)

        let errorCode = try XCTUnwrap(label(AccessibilityIdentifiers.NativeErrorPage.errorCodeLabel, in: subject.view))
        let advanced = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.advancedSection, in: subject.view))
        XCTAssertFalse(errorCode.isHidden)
        XCTAssertTrue(advanced.isHidden)
    }

    func testBadCertPage_hidesErrorCodeAndShowsAdvanced() throws {
        let subject = try createSubject(type: .badCert)

        let errorCode = try XCTUnwrap(label(AccessibilityIdentifiers.NativeErrorPage.errorCodeLabel, in: subject.view))
        let advanced = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.advancedSection, in: subject.view))
        XCTAssertTrue(errorCode.isHidden)
        XCTAssertFalse(advanced.isHidden)
    }

    func testGenericPage_showsTryAgainButton() throws {
        let subject = try createSubject(type: .generic)

        XCTAssertNotNil(view(AccessibilityIdentifiers.NativeErrorPage.reloadButton, in: subject.view))
        XCTAssertNil(view(AccessibilityIdentifiers.NativeErrorPage.goBackButton, in: subject.view))
    }

    func testBadCertPage_showsGoBackButton() throws {
        let subject = try createSubject(type: .badCert)

        XCTAssertNotNil(view(AccessibilityIdentifiers.NativeErrorPage.goBackButton, in: subject.view))
        XCTAssertNil(view(AccessibilityIdentifiers.NativeErrorPage.reloadButton, in: subject.view))
    }

    // MARK: - Helpers

    private func createSubject(type: NativeErrorPageType) throws -> RefactoredNativeErrorPageViewController {
        let errorPage = try XCTUnwrap(NativeErrorPageURL.make(type: type, originalURL: originalURL, errorCode: -1))
        let subject = RefactoredNativeErrorPageViewController(errorPage: errorPage,
                                                              windowUUID: .XCTestDefaultUUID,
                                                              tabManager: MockTabManager(),
                                                              themeManager: MockThemeManager())
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject)
        return subject
    }

    private func view(_ identifier: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == identifier { return root }
        return root.subviews.lazy.compactMap { self.view(identifier, in: $0) }.first
    }

    private func label(_ identifier: String, in root: UIView) -> UILabel? {
        return view(identifier, in: root) as? UILabel
    }
}
