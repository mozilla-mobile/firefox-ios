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
    static let termsOfUseHasOpenedNotification = TermsOfUse.TermsOfUseHasOpened

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
            return SupportUtils.URLForTermsOfUse
        case TermsOfUse.LinkPrivacyNotice:
            return SupportUtils.URLForPrivacyNotice
        case TermsOfUse.LinkLearnMore:
            return SupportUtils.URLForTopic("firefox-terms-of-use-faq", useMobilePath: false)
        default:
            return nil
        }
    }
}
