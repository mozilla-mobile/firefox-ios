// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class NativeErrorPageAdvancedViewTests: XCTestCase {
    func testConfigure_withoutProceedTitle_hidesCertificateButtons() throws {
        let subject = createSubject(proceedTitle: nil)

        let proceed = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.proceedButton, in: subject))
        let viewCertificate = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.viewCertificateLink,
                                                 in: subject))
        XCTAssertTrue(proceed.isHidden)
        XCTAssertTrue(viewCertificate.isHidden)
    }

    func testConfigure_withProceedTitle_showsProceedWithTitle() throws {
        let subject = createSubject(proceedTitle: "Proceed")

        let proceed = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.proceedButton, in: subject) as? UIButton)
        XCTAssertFalse(proceed.isHidden)
        XCTAssertEqual(proceed.configuration?.title, "Proceed")
    }

    func testConfigure_showsOneLabelPerDetail() {
        let subject = createSubject(details: ["First", "Second"])

        let detailLabels = views(AccessibilityIdentifiers.NativeErrorPage.advancedDetailLabel, in: subject)
            .compactMap { $0 as? UILabel }
        XCTAssertEqual(detailLabels.map(\.text), ["First", "Second"])
    }

    func testConfigure_showsErrorCode() throws {
        let subject = createSubject(errorCode: -1202)

        let errorCode = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.advancedErrorCodeLabel,
                                           in: subject) as? UILabel)
        XCTAssertTrue(errorCode.text?.contains("-1202") ?? false)
    }

    func testConfigure_headerAccessibilityLabelIncludesSummary() throws {
        let subject = createSubject(summary: "Summary text")

        let header = try XCTUnwrap(view(AccessibilityIdentifiers.NativeErrorPage.advancedSectionHeader, in: subject))
        XCTAssertTrue(header.accessibilityLabel?.contains("Summary text") ?? false)
    }

    // MARK: - Helpers

    private func createSubject(
        summary: String = "Summary",
        details: [String] = ["Detail"],
        proceedTitle: String? = nil,
        errorCode: Int = -1
    ) -> NativeErrorPageAdvancedView {
        let subject = NativeErrorPageAdvancedView()
        subject.configure(
            with: RefactoredNativeErrorPageModel.Advanced(summary: summary, details: details, proceedTitle: proceedTitle),
            errorCode: errorCode
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func view(_ identifier: String, in root: UIView) -> UIView? {
        return views(identifier, in: root).first
    }

    private func views(_ identifier: String, in root: UIView) -> [UIView] {
        let match = root.accessibilityIdentifier == identifier ? [root] : []
        return match + root.subviews.flatMap { views(identifier, in: $0) }
    }
}
