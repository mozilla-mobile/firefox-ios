// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Localizations
import Shared

enum TermsOfUseLinkType: CaseIterable {
    case termsOfUse
    case privacyNotice
    case learnMore

    var localizedText: String {
        switch self {
        case .termsOfUse:
            return String.localizedStringWithFormat(TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue)
        case .privacyNotice:
            return TermsOfUse.LinkPrivacyNotice
        case .learnMore:
            return TermsOfUse.LinkLearnMore
        }
    }

    var url: URL? {
        switch self {
        case .termsOfUse:
            return SupportUtils.URLForTermsOfUse
        case .privacyNotice:
            return SupportUtils.URLForPrivacyNotice
        case .learnMore:
            return SupportUtils.URLForTopic("firefox-terms-of-use-faq", useMobilePath: false)
        }
    }

    var actionType: TermsOfUseActionType {
        switch self {
        case .termsOfUse:
            return .termsLinkTapped
        case .privacyNotice:
            return .privacyLinkTapped
        case .learnMore:
            return .learnMoreLinkTapped
        }
    }

    static func linkType(for url: URL) -> TermsOfUseLinkType? {
        return TermsOfUseLinkType.allCases.first { $0.url == url }
    }
}

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
        return TermsOfUseLinkType.allCases.map { $0.localizedText }
    }

    static func linkURL(for term: String) -> URL? {
        return TermsOfUseLinkType.allCases.first { $0.localizedText == term }?.url
    }
}
