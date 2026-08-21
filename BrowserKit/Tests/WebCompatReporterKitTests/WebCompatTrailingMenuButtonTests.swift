// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatTrailingMenuButtonTests: XCTestCase {
    func testMenuAttachmentPoint_sitsAtTheTrailingEdge() {
        let subject = createSubject()

        XCTAssertEqual(subject.menuAttachmentPoint(for: makeConfiguration()), CGPoint(x: 320, y: 44))
    }

    func testMenuAttachmentPoint_mirrorsForRightToLeft() {
        let subject = createSubject()
        subject.semanticContentAttribute = .forceRightToLeft

        XCTAssertEqual(subject.menuAttachmentPoint(for: makeConfiguration()), CGPoint(x: 0, y: 44))
    }

    private func createSubject() -> WebCompatTrailingMenuButton {
        let subject = WebCompatTrailingMenuButton(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makeConfiguration() -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: nil)
    }
}
