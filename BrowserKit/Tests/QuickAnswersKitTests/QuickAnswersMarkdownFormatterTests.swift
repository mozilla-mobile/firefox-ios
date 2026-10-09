// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Testing

@testable import QuickAnswersKit

@Suite
@MainActor
struct QuickAnswersMarkdownFormatterTests {
    private let theme = LightTheme()

    @Test
    func test_format_withMarkdown_stripsMarkdownSyntax() {
        let subject = createSubject()

        let result = subject.format(markdown: "Lisbon is **sunny** in *spring*")

        #expect(result.string.trimmingCharacters(in: .whitespacesAndNewlines) == "Lisbon is sunny in spring")
    }

    @Test
    func test_format_withBoldText_appliesBoldFont() {
        let subject = createSubject()

        let result = subject.format(markdown: "**sunny**")

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
    }

    @Test
    func test_format_withLink_doesNotRenderLink() {
        let subject = createSubject()

        let result = subject.format(markdown: "[Lisbon](https://example.com)")

        var hasLink = false
        result.enumerateAttribute(.link, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil { hasLink = true }
        }
        #expect(!hasLink)
    }

    @Test
    func test_format_appliesThemeTextColor() {
        let subject = createSubject()

        let result = subject.format(markdown: "Lisbon")

        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        #expect(color == theme.colors.textPrimary)
    }

    private func createSubject() -> QuickAnswersMarkdownFormatter {
        return QuickAnswersMarkdownFormatter(theme: theme)
    }
}
