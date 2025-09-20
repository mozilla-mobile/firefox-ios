// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Down
import UIKit

class CustomStyler: DownStyler {
    // NOTE: The content is produced by an LLM; generated links may be unsafe or unreachable.
    // To keep the MVP safe, link rendering is disabled.
    override func style(link str: NSMutableAttributedString, title: String?, url: String?) {}

    override func style(image str: NSMutableAttributedString, title: String?, url: String?) {}
}

struct SummaryFormatter {
    private struct UX {
        static let headingSpacing: CGFloat = 16.0
        static let bodySpacing: CGFloat = 8.0
        static let listItemTopSpacing: CGFloat = 2.0
        static let listItemBottomSpacing: CGFloat = 4.0
    }
    let theme: any Theme

    func format(markdown: String) -> NSAttributedString? {
        let formatter = Down(markdownString: markdown)
        return try? formatter.toAttributedString(
            styler: CustomStyler(
                configuration: makeConfiguration()
            )
        )
    }

    private func makeConfiguration() -> DownStylerConfiguration {
        let heading5Style = NSMutableParagraphStyle()
        heading5Style.alignment = .center
        heading5Style.paragraphSpacingBefore = UX.headingSpacing

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacing = UX.bodySpacing

        let heading6Style = NSMutableParagraphStyle()
        heading6Style.paragraphSpacing = UX.headingSpacing
        heading6Style.paragraphSpacingBefore = 0

        let heading2Style = NSMutableParagraphStyle()
        heading2Style.paragraphSpacing = UX.headingSpacing
        heading2Style.paragraphSpacingBefore = UX.bodySpacing

        var paragraphStyle = StaticParagraphStyleCollection()
        paragraphStyle.heading5 = heading5Style
        paragraphStyle.body = bodyStyle
        paragraphStyle.heading6 = heading6Style
        paragraphStyle.heading2 = heading2Style

        let textColor = theme.colors.textPrimary
        return DownStylerConfiguration(
            fonts: StaticFontCollection(
                heading1: FXFontStyles.Regular.title1.scaledFont(),
                heading2: FXFontStyles.Regular.title2.scaledFont(),
                heading3: FXFontStyles.Regular.title3.scaledFont(),
                heading4: FXFontStyles.Regular.headline.scaledFont(),
                heading5: FXFontStyles.Regular.footnote.scaledFont(),
                heading6: FXFontStyles.Regular.caption2.scaledFont(),
                body: FXFontStyles.Regular.body.scaledFont(),
                code: FXFontStyles.Regular.body.monospacedFont(),
                listItemPrefix: FXFontStyles.Regular.body.scaledFont()
            ),
            colors: StaticColorCollection(
                heading1: textColor,
                heading2: textColor,
                heading3: textColor,
                heading4: textColor,
                heading5: theme.colors.textSecondary,
                heading6: theme.colors.textSecondary,
                body: textColor,
                code: textColor,
                link: textColor,
                quote: textColor,
                quoteStripe: textColor,
                thematicBreak: textColor,
                listItemPrefix: textColor,
                codeBlockBackground: .clear
            ),
            paragraphStyles: paragraphStyle,
            listItemOptions: ListItemOptions(
                spacingAbove: UX.listItemTopSpacing,
                spacingBelow: UX.listItemBottomSpacing
            )
        )
    }
}
