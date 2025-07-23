// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Localizations
import Shared

struct TermsOfUseStrings {
    static let titleText = TermsOfUse.Title

    static var descriptionText: String {
        return String.localizedStringWithFormat(TermsOfUse.Description, AppName.shortName.rawValue)
    }

    static let reviewAndAcceptText = TermsOfUse.ReviewAndAcceptText
    static let acceptButtonTitle = TermsOfUse.AcceptButton
    static let remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton

    static var termsOfUseInfoText: String {
        return "\(descriptionText)\n\n\(reviewAndAcceptText)"
    }

    static var linkTerms: [String] {
        return [
            String.localizedStringWithFormat(TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue),
            TermsOfUse.LinkPrivacyNotice,
            TermsOfUse.LinkLearnMore
        ]
    }

    static func linkURL(for term: String) -> URL? {
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

    private static func sumoFAQURL(_ topic: String) -> URL? {
        guard let escapedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let languageIdentifier = Locale.preferredLanguages.first else {
            return nil
        }
        return URL(string: "https://support.mozilla.org/1/firefox/\(AppInfo.appVersion)/iOS/\(languageIdentifier)/\(escapedTopic)")
    }
}
