// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Down
import UIKit

struct SummarizeErrorFormatter {
    let theme: Theme
    let isAccessibilityCategoryEnabled: Bool
    let viewModel: SummarizeViewConfiguration

    private var parserConfiguration: DownStylerConfiguration {
        let centeredParagraphStyle = NSMutableParagraphStyle()
        centeredParagraphStyle.alignment = .center
        centeredParagraphStyle.paragraphSpacingBefore = 16
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.alignment = .center
        bodyStyle.paragraphSpacingBefore = 2
        var paragraphStyles = StaticParagraphStyleCollection()
        paragraphStyles.heading1 = centeredParagraphStyle
        paragraphStyles.heading2 = centeredParagraphStyle
        paragraphStyles.heading3 = centeredParagraphStyle
        paragraphStyles.body = bodyStyle
        let textColor = theme.colors.textOnDark
        return DownStylerConfiguration(
            fonts: StaticFontCollection(
                heading1: FXFontStyles.Bold.headline.scaledFont(),
                heading2: FXFontStyles.Regular.body.scaledFont(),
                heading3: FXFontStyles.Regular.subheadline.scaledFont(),
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
                heading3: textColor.withAlphaComponent(0.8),
                heading4: textColor,
                heading5: theme.colors.textSecondary,
                heading6: theme.colors.textSecondary,
                body: textColor,
                code: textColor,
                link: .red,
                quote: textColor,
                quoteStripe: textColor,
                thematicBreak: textColor,
                listItemPrefix: textColor,
                codeBlockBackground: .clear
            ),
            paragraphStyles: paragraphStyles,
            listItemOptions: ListItemOptions(
                spacingAbove: 0,
                spacingBelow: 0
            )
        )
    }

    func format(error: SummarizerError) -> NSAttributedString? {
        let markDown = generateMarkdown(error: error)
        let parser = Down(markdownString: markDown)
        return try? parser.toAttributedString(styler: DownStyler(configuration: parserConfiguration))
    }

    private func generateMarkdown(error: SummarizerError) -> String {
        switch error {
        case .tosConsentMissing:
            if isAccessibilityCategoryEnabled {
                return """
                # \(viewModel.termOfService.titleLabel)
                [\(viewModel.termOfService.linkButtonLabel)](\(viewModel.termOfService.linkButtonURL?.absoluteString ?? ""))
                """
            }
            return """
            # \(viewModel.termOfService.titleLabel)
            ### \(viewModel.termOfService.descriptionText)
            [\(viewModel.termOfService.linkButtonLabel)](\(viewModel.termOfService.linkButtonURL?.absoluteString ?? ""))
            """
        default:
            return """
            ## \(error.description(for: viewModel.errorMessages))
            """
        }
    }
}
