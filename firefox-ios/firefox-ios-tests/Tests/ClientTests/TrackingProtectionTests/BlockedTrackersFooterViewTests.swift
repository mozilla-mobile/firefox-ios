// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class BlockedTrackersFooterViewTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var subject: BlockedTrackersFooterView!
    private var mockThemeManager: MockThemeManager!
    private var theme: Theme!

    override func setUp() async throws {
        try await super.setUp()
        subject = BlockedTrackersFooterView(reuseIdentifier: "test reuse identifier")
        mockThemeManager = MockThemeManager()
        theme = mockThemeManager.getCurrentTheme(for: windowUUID)
    }

    override func tearDown() async throws {
        subject = nil
        mockThemeManager = nil
        theme = nil
        try await super.tearDown()
    }

    func testInitConfiguresTextViewCorrectly() {
        let textView = subject.trackersBlockedInfoTextView

        XCTAssertFalse(textView.isEditable)
        XCTAssertFalse(textView.isScrollEnabled)
        XCTAssertEqual(textView.backgroundColor, .clear)
        XCTAssertTrue(textView.adjustsFontForContentSizeCategory)
    }

    func testMakeAttributedDescriptionSetsAttributedText() {
        let text = "This is an information! Learn more"

        subject.configure(with: text, linkedText: "Learn more", url: nil, theme: theme)
        XCTAssertEqual(subject.trackersBlockedInfoTextView.attributedText?.string, text)
    }

    func testMakeAttributedDescriptionAddsLinkAttribute_whenURLProvided() {
        let text = "Learn more about tracking protection! Learn more"
        let linkedText = "Learn more"
        let url = URL(string: "https://example.com")!

        subject.configure(with: text, linkedText: linkedText, url: url, theme: theme)

        let attributedText = subject.trackersBlockedInfoTextView.attributedText!
        let range = (text as NSString).range(of: linkedText)

        let link = attributedText.attribute(.link, at: range.location, effectiveRange: nil) as? URL

        XCTAssertEqual(link, url)
    }

    func testMakeAttributedDescription_doesNotAddLink_whenURLIsNil() {
        let text = "Learn more about tracking protection! Learn more"
        let linkedText = "Learn more"

        subject.configure(with: text, linkedText: linkedText, url: nil, theme: theme)

        let attributedText = subject.trackersBlockedInfoTextView.attributedText!
        let range = (text as NSString).range(of: linkedText)

        let link = attributedText.attribute(.link, at: range.location, effectiveRange: nil)

        XCTAssertNil(link)
    }

    func testApplyThemeSetsLinkTextAttributes() {
        subject.applyTheme(theme: theme)

        let attributes = subject.trackersBlockedInfoTextView.linkTextAttributes
        let color = attributes?[.foregroundColor] as? UIColor

        XCTAssertEqual(color, theme.colors.textAccent)
    }
}
