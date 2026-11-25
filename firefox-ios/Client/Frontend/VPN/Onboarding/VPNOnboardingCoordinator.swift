// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

@MainActor
protocol VPNOnboardingCoordinatorDelegate: AnyObject {
    func vpnOnboardingDidTapCTA(from coordinator: Coordinator)
}

@available(iOS 17.0, *)
@MainActor
final class VPNOnboardingCoordinator: BaseCoordinator {
    private enum UX {
        static let sheetHeightRatio: CGFloat = 0.75
        static let dataLimitInGB = 5
    }

    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var delegate: VPNOnboardingCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let tabManager: TabManager
    private let prefs: Prefs
    private let telemetry: VPNClientTelemetry
    private let themeManager: ThemeManager
    private let featureFlagsProvider: FeatureFlagProviding
    private let traitCollectionProvider: () -> UITraitCollection
    private let onOpenURL: (URL) -> Void

    init(
        router: Router,
        windowUUID: WindowUUID,
        tabManager: TabManager,
        prefs: Prefs,
        telemetry: VPNClientTelemetry = DefaultVPNTelemetry(),
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        traitCollectionProvider: @escaping () -> UITraitCollection = { .current },
        onOpenURL: @escaping (URL) -> Void
    ) {
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.prefs = prefs
        self.telemetry = telemetry
        self.themeManager = themeManager
        self.featureFlagsProvider = featureFlagsProvider
        self.traitCollectionProvider = traitCollectionProvider
        self.onOpenURL = onOpenURL
        super.init(router: router)
    }

    func shouldShow() -> Bool {
        guard isEligible() else { return false }
        FxNimbus.shared.features.vpnFeature.recordExposure()
        return areFlagsEnabled()
    }

    private func isEligible() -> Bool {
        guard let selectedTab = tabManager.selectedTab, !selectedTab.isFxHomeTab else { return false }
        return prefs.boolForKey(PrefsKeys.VPNSettings.onboardingSheetShown) != true
    }

    private func areFlagsEnabled() -> Bool {
        featureFlagsProvider.isEnabled(.vpnFeature) && featureFlagsProvider.isEnabled(.vpnOnboardingSheet)
    }

    func start() {
        let controller = OnboardingSheetViewController(
            windowUUID: windowUUID,
            themeManager: themeManager,
            configuration: makeConfiguration(),
            onCTA: { [weak self] in
                self?.didTapCTA()
            },
            onLearnMore: { [weak self] in
                self?.didTapLearnMore()
            },
            onDismiss: { [weak self] in
                self?.didTapClose()
            }
        )
        controller.modalPresentationStyle = .formSheet
        if traitCollectionProvider().horizontalSizeClass != .regular {
            controller.sheetPresentationController?.detents = [
                .custom { context in context.maximumDetentValue * UX.sheetHeightRatio },
                .large()
            ]
        }

        // Only runs on swipe down, dismissing through the router drops the completion.
        router.present(controller, animated: true) { [weak self] in
            self?.telemetry.recordOnboardingCancelled()
            self?.finish()
        }
        prefs.setBool(true, forKey: PrefsKeys.VPNSettings.onboardingSheetShown)
        telemetry.recordOnboardingShown()
    }

    private func didTapCTA() {
        telemetry.recordOnboardingPrimaryButtonTapped()
        router.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.vpnOnboardingDidTapCTA(from: self)
        }
    }

    private func didTapLearnMore() {
        telemetry.recordOnboardingLearnMoreLinkTapped()
        if let url = VPNSettingsViewController.learnMoreURL {
            onOpenURL(url)
        }
        router.dismiss(animated: true)
        finish()
    }

    private func didTapClose() {
        telemetry.recordOnboardingCancelled()
        router.dismiss(animated: true)
        finish()
    }

    private func makeConfiguration() -> OnboardingSheetConfiguration {
        let appName = AppName.shortName.rawValue
        return OnboardingSheetConfiguration(
            heroImageName: StandardImageIdentifiers.Large.globe,
            heroGradient: .accent,
            title: String(format: .VPN.Onboarding.Title, appName),
            description: .VPN.Onboarding.Subheading,
            rows: [
                OnboardingSheetRow(
                    imageName: StandardImageIdentifiers.ExtraLarge.wifi,
                    title: .VPN.Onboarding.WifiSubheading,
                    subtitle: String(format: .VPN.Onboarding.WifiBody, appName)
                ),
                OnboardingSheetRow(
                    imageName: StandardImageIdentifiers.ExtraLarge.checkmarkBadge,
                    title: String(format: .VPN.Onboarding.LimitSubheading, String(UX.dataLimitInGB)),
                    subtitle: .VPN.Onboarding.LimitBody
                )
            ],
            learnMoreTitle: .VPN.Settings.LearnMore,
            ctaTitle: .VPN.Onboarding.TurnOnVPNButton,
            closeAccessibilityLabel: .CloseButtonTitle,
            ctaAccessibilityIdentifier: AccessibilityIdentifiers.VPNOnboardingSheet.ctaButton,
            learnMoreAccessibilityIdentifier: AccessibilityIdentifiers.VPNOnboardingSheet.learnMoreButton,
            closeAccessibilityIdentifier: AccessibilityIdentifiers.VPNOnboardingSheet.closeButton
        )
    }

    private func finish() {
        parentCoordinator?.didFinish(from: self)
    }
}
