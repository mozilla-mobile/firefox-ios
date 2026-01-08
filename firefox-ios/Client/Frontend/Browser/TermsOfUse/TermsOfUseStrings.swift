// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Localizations
import Shared

extension TermsOfUseContentOption {
    var headline: String {
        switch self {
        case .value0:
            return TermsOfUse.Title
        case .value1:
            return TermsOfUse.TitleValue1
        case .value2:
            return String.localizedStringWithFormat(TermsOfUse.TitleValue2, AppName.shortName.rawValue)
        }
    }

    var reviewAndAcceptText: String {
        switch self {
        case .value0:
            return TermsOfUse.ReviewAndAcceptText
        case .value1, .value2:
            return String.localizedStringWithFormat(TermsOfUse.LearnMoreHere, TermsOfUse.LinkHereText)
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
    let value: TermsOfUseContentOption

    init(value: TermsOfUseContentOption = .value0) {
        self.value = value
    }

    var titleText: String {
        return value.headline
    }

    static var descriptionText: String {
        return String.localizedStringWithFormat(TermsOfUse.Description, AppName.shortName.rawValue)
    }

    var reviewAndAcceptText: String {
        return value.reviewAndAcceptText
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
        // All variants have the same 3 links: Terms of Use, Privacy Notice, and a third link
        var links = Self.linkTerms
        
        // For variants 1 and 2, replace "Learn more" with "here" (same link, different text)
        if value == .value1 || value == .value2 {
            // Remove "Learn more" and add "here" instead
            links = links.filter { $0 != TermsOfUseLinkType.learnMore.localizedText }
            links.append(TermsOfUseLinkType.here.localizedText)
        }
        
        return links
    }

    static func linkURL(for term: String) -> URL? {
        return TermsOfUseLinkType.allCases.first { $0.localizedText == term }?.url
    }

    func linkURL(for term: String) -> URL? {
        return Self.linkURL(for: term)
    }
}
