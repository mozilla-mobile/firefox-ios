// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Glean
import MozillaAppServices
import OnboardingKit

protocol VersionProviding: Sendable {
    func object(forInfoDictionaryKey key: String) -> Any?
}

extension Bundle: VersionProviding {}

struct TermsOfServiceManager: FeatureFlaggable, Sendable {
    var prefs: Prefs
    private let bundle: VersionProviding

    init(prefs: Prefs, bundle: VersionProviding = Bundle.main) {
        self.prefs = prefs
        self.bundle = bundle
    }

    var isModernOnboardingEnabled: Bool {
        featureFlags.isFeatureEnabled(.modernOnboardingUI, checking: .buildAndUser)
    }

    var isFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser)
    }

    var isAccepted: Bool {
        prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
    }

    var shouldShowScreen: Bool {
        guard featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser) else { return false }
        return prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) == nil
    }

    func setAccepted(acceptedDate: Date) {
        prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        prefs.setString(String(TermsOfUseTelemetry().termsOfUseVersion), forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)
    }

    func shouldSendTechnicalData(telemetryValue: Bool, studiesValue: Bool) {
        DefaultGleanWrapper().setUpload(isEnabled: telemetryValue)
        Experiments.setStudiesSetting(studiesValue)
        Experiments.setTelemetrySetting(telemetryValue)
    }

    // MARK: - Terms of Use Configuration

    static var brandRefreshTermsOfUseConfiguration: OnboardingKitCardInfoModel {
        let termsOfUseLink = String(
            format: .Onboarding.Modern.BrandRefresh.TermsOfUse.TermsOfUseLink,
            AppName.shortName.rawValue
        )
        let termsOfUseAgreement = String(
            format: .Onboarding.Modern.BrandRefresh.TermsOfUse.TermsOfUseAgreement,
            termsOfUseLink
        )
        let privacyNoticeLink = String.Onboarding.Modern.BrandRefresh.TermsOfUse.PrivacyNoticeLink
        let privacyAgreement = String(
            format: .Onboarding.Modern.BrandRefresh.TermsOfUse.PrivacyNoticeAgreement,
            AppName.shortName.rawValue,
            privacyNoticeLink
        )
        let manageLink = String.Onboarding.TermsOfService.ManageLink
        let manageAgreement = String(
            format: String.Onboarding.Modern.TermsOfService.ManagePreferenceAgreement,
            AppName.shortName.rawValue,
            MozillaName.shortName.rawValue,
            manageLink
        )

        return OnboardingKitCardInfoModel(
            cardType: .basic,
            name: "tos",
            order: 20,
            title: String(format: .Onboarding.TermsOfService.Title, AppName.shortName.rawValue),
            body: String.Onboarding.Modern.BrandRefresh.TermsOfUse.Description,
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: String.Onboarding.Modern.BrandRefresh.TermsOfUse.AgreementButtonTitleV2,
                    action: OnboardingActions.endOnboarding
                )
            ),
            multipleChoiceButtons: [],
            onboardingType: .freshInstall,
            a11yIdRoot: AccessibilityIdentifiers.TermsOfService.root,
            imageID: ImageIdentifiers.homeHeaderLogoBall,
            embededLinkText: [
                EmbeddedLink(
                    fullText: termsOfUseAgreement,
                    linkText: termsOfUseLink,
                    action: .openTermsOfService
                ),
                EmbeddedLink(
                    fullText: privacyAgreement,
                    linkText: privacyNoticeLink,
                    action: .openPrivacyNotice
                ),
                EmbeddedLink(
                    fullText: manageAgreement,
                    linkText: manageLink,
                    action: .openManageSettings
                )
            ]
        )
    }
}
