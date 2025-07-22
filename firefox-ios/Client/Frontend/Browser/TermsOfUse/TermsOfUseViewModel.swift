// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Localizations
import Shared

struct TermsOfUseViewModel {
    let titleText = TermsOfUse.Title
    let descriptionText: String
    let reviewAndAcceptText = TermsOfUse.ReviewAndAcceptText
    let acceptButtonTitle = TermsOfUse.AcceptButton
    let remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton

    var onAccept: (() -> Void)?
    var onNotNow: (() -> Void)?

    init(
        onAccept: (() -> Void)? = { TermsOfUseManager.shared.markAccepted() },
        onNotNow: (() -> Void)? = { TermsOfUseManager.shared.markDismissed() }
    ) {
        self.onAccept = onAccept
        self.onNotNow = onNotNow

        self.descriptionText = String.localizedStringWithFormat(
            TermsOfUse.Description,
            AppName.shortName.rawValue
        )
    }

    var combinedText: String {
        "\(descriptionText)\n\n\(reviewAndAcceptText)"
    }

    var linkTerms: [String] {
        [
            String.localizedStringWithFormat(TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue),
            TermsOfUse.LinkPrivacyNotice,
            TermsOfUse.LinkLearnMore
        ]
    }

    func linkURL(for term: String) -> URL? {
        switch term {
        case String.localizedStringWithFormat(TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue):
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

    func markToUAppeared() {
        TermsOfUseManager.shared.didShowThisLaunch = true
    }
}
