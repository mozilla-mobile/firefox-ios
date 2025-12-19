// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Localizations
import Shared

enum TermsOfUseStringVariant: Int, CaseIterable {
    case variant0 = 0
    case variant1 = 1
    case variant2 = 2

    var headline: String {
        switch self {
        case .variant0:
            return TermsOfUse.Title
        case .variant1:
            return TermsOfUse.TitleVariant1
        case .variant2:
            return String.localizedStringWithFormat(TermsOfUse.TitleVariant2, AppName.shortName.rawValue)
        }
    }

    var reviewAndAcceptText: String {
        switch self {
        case .variant0:
            return TermsOfUse.ReviewAndAcceptText
        case .variant1, .variant2:
            return TermsOfUse.LearnMoreHere
        }
    }
}

enum TermsOfUseLinkType: CaseIterable {
    case termsOfUse
    case privacyNotice
    case learnMore
    case here

    var localizedText: String {
        switch self {
        case .termsOfUse:
            return String.localizedStringWithFormat(TermsOfUse.LinkTermsOfUse, AppName.shortName.rawValue)
        case .privacyNotice:
            return TermsOfUse.LinkPrivacyNotice
        case .learnMore:
            return TermsOfUse.LinkLearnMore
        case .here:
            return TermsOfUse.LinkHereText
        }
    }

    var url: URL? {
        switch self {
        case .termsOfUse:
            return SupportUtils.URLForTermsOfUse
        case .privacyNotice:
            return SupportUtils.URLForPrivacyNotice
        case .learnMore, .here:
            return SupportUtils.URLForTopic("firefox-terms-of-use-faq", useMobilePath: false)
        }
    }

    var actionType: TermsOfUseActionType {
        switch self {
        case .termsOfUse:
            return .termsLinkTapped
        case .privacyNotice:
            return .privacyLinkTapped
        case .learnMore, .here:
            return .learnMoreLinkTapped
        }
    }

    static func linkType(for url: URL) -> TermsOfUseLinkType? {
        return TermsOfUseLinkType.allCases.first { $0.url == url }
    }
}

struct TermsOfUseStrings {
    let variant: TermsOfUseStringVariant

    init(variant: TermsOfUseStringVariant = .variant0) {
        self.variant = variant
    }

    var titleText: String {
        return variant.headline
    }

    static var descriptionText: String {
        return String.localizedStringWithFormat(TermsOfUse.Description, AppName.shortName.rawValue)
    }

    var reviewAndAcceptText: String {
        return variant.reviewAndAcceptText
    }

    static let acceptButtonTitle = TermsOfUse.AcceptButton
    static let remindMeLaterButtonTitle = TermsOfUse.RemindMeLaterButton
    static let termsOfUseHasOpenedNotification = TermsOfUse.TermsOfUseHasOpened

    var termsOfUseInfoText: String {
        return "\(Self.descriptionText)\n\n\(reviewAndAcceptText)"
    }

    static var linkTerms: [String] {
        return TermsOfUseLinkType.allCases.map { $0.localizedText }
    }

    var linkTerms: [String] {
        return Self.linkTerms
    }

    static func linkURL(for term: String) -> URL? {
        return TermsOfUseLinkType.allCases.first { $0.localizedText == term }?.url
    }

    func linkURL(for term: String) -> URL? {
        return Self.linkURL(for: term)
    }
}
