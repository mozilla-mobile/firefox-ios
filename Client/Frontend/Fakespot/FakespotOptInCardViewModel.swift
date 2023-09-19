// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import ComponentLibrary

struct FakespotOptInCardViewModel {
    private struct UX {
        static let contentStackViewPadding: CGFloat = 16
        static let bodyFirstParagraphLabelFontSize: CGFloat = 15
    }

    public enum PartnerWebsite: String, CaseIterable {
        case amazon
        case walmart
        case bestbuy

        static func orderWebsites(for siteName: String?) -> [String] {
            let lowercasedName = siteName?.lowercased() ?? "amazon"
            var currentPartnerWebsites = PartnerWebsite.allCases.map { $0.rawValue }

            // just in case this card will be shown from an unpartnered website in the future
            guard currentPartnerWebsites.contains(lowercasedName) else {
                currentPartnerWebsites[2] = "Best Buy"
                return currentPartnerWebsites.map { $0.capitalized }
            }

            var websitesOrder = currentPartnerWebsites.filter { $0 != lowercasedName }
            if lowercasedName == "bestbuy" {
                websitesOrder.insert("Best Buy", at: 0)
            } else {
                websitesOrder.insert(lowercasedName.capitalized, at: 0)
            }

            return websitesOrder.map { $0.capitalized }
        }
    }

    private let tabManager: TabManager
    private let prefs: Prefs
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.card
    var productSitename: String?

    // MARK: Labels
    let headerTitleLabel: String = .Shopping.OptInCardHeaderTitle
    let headerLabelA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.headerTitle
    let bodyFirstParagraphLabel: String = .Shopping.OptInCardCopy
    let bodyFirstParagraphA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.optInCopy
    let disclaimerTextLabel: String = .Shopping.OptInCardDisclaimerText
    let disclaimerTextLabelA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.disclaimerText

    // MARK: Buttons
    let learnMoreButton: String = .Shopping.OptInCardLearnMoreButtonTitle
    let learnMoreButtonA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.learnMoreButton
    let termsOfUseButton: String = .Shopping.OptInCardTermsOfUse
    let termsOfUseButtonA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.termsOfUseButton
    let privacyPolicyButton: String = .Shopping.OptInCardPrivacyPolicy
    let privacyPolicyButtonA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.privacyPolicyButton
    let mainButton: String = .Shopping.OptInCardMainButtonTitle
    let mainButtonA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.mainButton
    let secondaryButton: String = .Shopping.OptInCardSecondaryButtonTitle
    let secondaryButtonA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.secondaryButton

    // MARK: Init
    init(profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        self.tabManager = tabManager
        prefs = profile.prefs
    }

    // MARK: Actions
    func onTapLearnMore() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingLearnMoreButton)
        //        tabManager.addTabsForURLs([], zombie: false, shouldSelectTab: true) // no urls yet, will be added in FXIOS-7383
    }

    func onTapTermsOfUse() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingTermsOfUseButton)
    }

    func onTapPrivacyPolicy() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingPrivacyPolicyButton)
    }

    func onTapMainButton() {
        prefs.setBool(true, forKey: PrefsKeys.Shopping2023OptIn)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingOptIn)
    }

    func onTapSecondaryButton() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingNotNowButton)
    }

    // MARK: Text methods
    var firstParagraphText: NSAttributedString {
        let websites = PartnerWebsite.orderWebsites(for: productSitename)
        let font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                          size: UX.bodyFirstParagraphLabelFontSize)
        let boldFont = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body,
                                                                  size: UX.bodyFirstParagraphLabelFontSize)
        let plainText = String.localizedStringWithFormat(bodyFirstParagraphLabel, websites[0], websites[1], websites[2])
        return plainText.attributedText(boldPartsOfString: websites, initialFont: font, boldFont: boldFont)
    }

    var disclaimerText: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = UX.contentStackViewPadding
        paragraphStyle.headIndent = UX.contentStackViewPadding
        paragraphStyle.tailIndent = UX.contentStackViewPadding

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle
        ]

        return NSAttributedString(string: disclaimerTextLabel, attributes: attributes)
    }
}
