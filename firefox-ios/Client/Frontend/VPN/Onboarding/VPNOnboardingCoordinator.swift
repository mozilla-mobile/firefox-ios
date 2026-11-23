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

@available(iOS 27.2, *)
@MainActor
final class VPNOnboardingCoordinator: BaseCoordinator {
    private enum UX {
        static let sheetHeightRatio: CGFloat = 2.0 / 3.0
    }

    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var delegate: VPNOnboardingCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let tabManager: TabManager
    private let prefs: Prefs
    private let telemetry: VPNClientTelemetry
    private let vpnManager: VPNRunnable
    private let themeManager: ThemeManager
    private let featureFlagsProvider: FeatureFlagProviding
    private let onOpenURL: (URL) -> Void

    init(
        router: Router,
        windowUUID: WindowUUID,
        tabManager: TabManager,
        prefs: Prefs,
        telemetry: VPNClientTelemetry = DefaultVPNTelemetry(),
        vpnManager: VPNRunnable = AppContainer.shared.resolve(),
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        onOpenURL: @escaping (URL) -> Void
    ) {
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.prefs = prefs
        self.telemetry = telemetry
        self.vpnManager = vpnManager
        self.themeManager = themeManager
        self.featureFlagsProvider = featureFlagsProvider
        self.onOpenURL = onOpenURL
        super.init(router: router)
    }

    /// False until the VPN usage has been fetched, since the sheet shows the account's data limit.
    func shouldShow() -> Bool {
        guard let selectedTab = tabManager.selectedTab,
              !selectedTab.isFxHomeTab,
              vpnManager.dataLimitInGB > 0,
              featureFlagsProvider.isEnabled(.vpnFeature),
              featureFlagsProvider.isEnabled(.vpnOnboardingSheet)
        else { return false }
        return prefs.boolForKey(PrefsKeys.VPNSettings.onboardingSheetShown) != true
    }

    func start() {
        let controller = OnboardingSheetViewController(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: makeViewModel(),
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
        controller.modalPresentationStyle = .pageSheet
        controller.sheetPresentationController?.detents = [
            .custom { context in context.maximumDetentValue * UX.sheetHeightRatio }
        ]

        // Only runs on swipe down, dismissing through the router drops the completion.
        router.present(controller, animated: true) { [weak self] in
            self?.telemetry.recordOnboardingCancelled()
            self?.finish()
        }
        prefs.setBool(true, forKey: PrefsKeys.VPNSettings.onboardingSheetShown)
        telemetry.recordOnboardingShown()
    }

    private func didTapCTA() {
        telemetry.recordOnboardingCTATapped()
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

    private func makeViewModel() -> OnboardingSheetViewModel {
        let appName = AppName.shortName.rawValue
        let dataLimit = VPNHelpers.formatted(gigabytes: vpnManager.dataLimitInGB)
        return OnboardingSheetViewModel(
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
                    title: String(format: .VPN.Onboarding.LimitSubheading, dataLimit),
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
