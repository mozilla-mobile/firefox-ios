// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class BlockedTrackersFooterViewTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockThemeManager: MockThemeManager!
    private var theme: Theme!

    override func setUp() async throws {
        try await super.setUp()
        mockThemeManager = MockThemeManager()
        theme = mockThemeManager.getCurrentTheme(for: windowUUID)
    }

    override func tearDown() async throws {
        mockThemeManager = nil
        theme = nil
        try await super.tearDown()
    }

    func testGetAttributedText_setsAttributedText() {
        let subject = createSubject()
        let text = "This is an information! Learn more"

        let attributedText = subject.getAttributedText(with: text, linkedText: "Learn more", url: nil, theme: theme)
        XCTAssertEqual(attributedText.string, text)
    }

    func testGetAttributedText_addsLinkAttribute_whenURLProvided() {
        let subject = createSubject()
        let text = "Learn more about tracking protection! Learn more"
        let linkedText = "Learn more"
        let url = URL(string: "https://example.com")!

        let attributedText = subject.getAttributedText(with: text, linkedText: linkedText, url: url, theme: theme)
        let range = (text as NSString).range(of: linkedText)
        let link = attributedText.attribute(.link, at: range.location, effectiveRange: nil) as? URL

        XCTAssertEqual(link, url)
    }

    func testGetAttributedText_doesNotAddLink_whenURLIsNil() {
        let subject = createSubject()
        let text = "Learn more about tracking protection! Learn more"
        let linkedText = "Learn more"

        let attributedText = subject.getAttributedText(with: text, linkedText: linkedText, url: nil, theme: theme)
        let range = (text as NSString).range(of: linkedText)
        let link = attributedText.attribute(.link, at: range.location, effectiveRange: nil)

        XCTAssertNil(link)
    }

    private func createSubject() -> BlockedTrackersFooterView {
        let subject = BlockedTrackersFooterView(reuseIdentifier: "test reuse identifier")
        trackForMemoryLeaks(subject)
        return subject
    }
}
