// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Localizations

struct ToUBottomSheetViewModel {
    let titleText = TermsOfUse.Title
    let descriptionText = TermsOfUse.Description
    let acceptButtonTitle = TermsOfUse.AcceptButton
    let remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton

    var onAccept: (() -> Void)?
    var onNotNow: (() -> Void)?

    private let terms = [
        TermsOfUse.LinkTermsOfUse,
        TermsOfUse.LinkPrivacyNotice,
        TermsOfUse.LinkLearnMore
    ]

    init(
        onAccept: (() -> Void)? = { ToUManager.shared.markAccepted() },
        onNotNow: (() -> Void)? = { ToUManager.shared.markDismissed() }
    ) {
        self.onAccept = onAccept
        self.onNotNow = onNotNow
    }

    func markToUAppeared() {
        ToUManager.shared.didShowThisLaunch = true
    }

    func makeAttributedDescription(theme: Theme) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.alignment = .left

        let attributed = NSMutableAttributedString(
            string: descriptionText,
            attributes: [
                .font: FXFontStyles.Regular.body.scaledFont(),
                .foregroundColor: theme.colors.textSecondary,
                .paragraphStyle: paragraphStyle
            ]
        )

        for term in terms {
            if let url = linkURL(for: term),
               let range = attributed.string.range(of: term) {
                let nsRange = NSRange(range, in: attributed.string)
                attributed.addAttribute(.link, value: url, range: nsRange)
            }
        }

        return attributed
    }

    func linkURL(for term: String) -> URL? {
        switch term {
        case TermsOfUse.LinkTermsOfUse:
            return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
        case TermsOfUse.LinkPrivacyNotice:
            return URL(string: "https://www.mozilla.org/privacy/firefox/")
        case TermsOfUse.LinkLearnMore:
            return sumoFAQURL("firefox-terms-of-use-faq")
        default:
            return nil
        }
    }

    private func sumoFAQURL(_ topic: String) -> URL? {
        guard let escapedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let languageIdentifier = Locale.preferredLanguages.first else {
            return nil
        }
        return URL(string: "https://support.mozilla.org/1/firefox/\(AppInfo.appVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")
    }
}
