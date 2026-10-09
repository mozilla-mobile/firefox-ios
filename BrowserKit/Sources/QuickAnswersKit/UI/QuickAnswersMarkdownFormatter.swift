// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Down
import UIKit

/// Links and images are not rendered since the content is produced by an LLM and could be unsafe or unreachable.
final class QuickAnswersMarkdownStyler: DownStyler {
    override func style(link str: NSMutableAttributedString, title: String?, url: String?) {}

    override func style(image str: NSMutableAttributedString, title: String?, url: String?) {}
}

struct QuickAnswersMarkdownFormatter {
    private struct UX {
        static let paragraphSpacing: CGFloat = 8.0
        static let headingSpacing: CGFloat = 8.0
        static let listItemTopSpacing: CGFloat = 2.0
        static let listItemBottomSpacing: CGFloat = 4.0
    }

    let theme: any Theme

    /// Falls back to the raw markdown when it can't be parsed, so the answer is never lost.
    func format(markdown: String) -> NSAttributedString {
        let attributedString = try? Down(markdownString: markdown).toAttributedString(
            styler: QuickAnswersMarkdownStyler(configuration: makeConfiguration())
        )
        return attributedString ?? NSAttributedString(
            string: markdown,
            attributes: [
                .font: FXFontStyles.Regular.body.scaledFont(),
                .foregroundColor: theme.colors.textPrimary
            ]
        )
    }

    private func makeConfiguration() -> DownStylerConfiguration {
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacing = UX.paragraphSpacing

        let headingStyle = NSMutableParagraphStyle()
        headingStyle.paragraphSpacing = UX.headingSpacing
        headingStyle.paragraphSpacingBefore = UX.headingSpacing

        var paragraphStyles = StaticParagraphStyleCollection()
        paragraphStyles.body = bodyStyle
        paragraphStyles.heading1 = headingStyle
        paragraphStyles.heading2 = headingStyle
        paragraphStyles.heading3 = headingStyle
        paragraphStyles.heading4 = headingStyle
        paragraphStyles.heading5 = headingStyle
        paragraphStyles.heading6 = headingStyle

        let textColor = theme.colors.textPrimary
        return DownStylerConfiguration(
            fonts: StaticFontCollection(
                heading1: FXFontStyles.Bold.title3.scaledFont(),
                heading2: FXFontStyles.Bold.headline.scaledFont(),
                heading3: FXFontStyles.Bold.body.scaledFont(),
                heading4: FXFontStyles.Bold.body.scaledFont(),
                heading5: FXFontStyles.Bold.subheadline.scaledFont(),
                heading6: FXFontStyles.Bold.subheadline.scaledFont(),
                body: FXFontStyles.Regular.body.scaledFont(),
                code: FXFontStyles.Regular.body.monospacedFont(),
                listItemPrefix: FXFontStyles.Regular.body.scaledFont()
            ),
            colors: StaticColorCollection(
                heading1: textColor,
                heading2: textColor,
                heading3: textColor,
                heading4: textColor,
                heading5: textColor,
                heading6: textColor,
                body: textColor,
                code: textColor,
                link: textColor,
                quote: theme.colors.textSecondary,
                quoteStripe: theme.colors.borderPrimary,
                thematicBreak: theme.colors.borderPrimary,
                listItemPrefix: textColor,
                codeBlockBackground: .clear
            ),
            paragraphStyles: paragraphStyles,
            listItemOptions: ListItemOptions(
                spacingAbove: UX.listItemTopSpacing,
                spacingBelow: UX.listItemBottomSpacing
            )
        )
    }
}
