// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import XCTest
import Common
import TestKit

@MainActor
final class QuickAnswersContentViewTests: XCTestCase {
    func testConfigureFooter_withExaModel_setsPoweredByExaText() {
        let subject = createSubject()

        subject.configureFooter(model: .exa)

        XCTAssertEqual(subject.footerText, "Powered by Exa")
    }

    func testConfigureFooter_withLinerModel_setsPoweredByLinerText() {
        let subject = createSubject()

        subject.configureFooter(model: .liner)

        XCTAssertEqual(subject.footerText, "Powered by Liner")
    }

    func testConfigureFooter_beforeConfiguration_footerIsHidden() {
        let subject = createSubject()

        XCTAssertEqual(subject.footerAlpha, 0.0)
        XCTAssertNil(subject.footerText)
    }

    func testConfigureFooter_makesFooterVisible() {
        let subject = createSubject()

        subject.configureFooter(model: .exa)

        XCTAssertEqual(subject.footerAlpha, 1.0)
    }

    // MARK: - Helper
    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuickAnswersContentView {
        let subject = QuickAnswersContentView()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
