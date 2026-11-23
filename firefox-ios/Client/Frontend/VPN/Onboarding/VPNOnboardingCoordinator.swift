// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit
import VPNKit

@MainActor
protocol VPNOnboardingCoordinatorDelegate: AnyObject {
    func vpnOnboardingDidTapCTA(from coordinator: VPNOnboardingCoordinator)
}

@MainActor
final class VPNOnboardingCoordinator: BaseCoordinator {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var delegate: VPNOnboardingCoordinatorDelegate?

    private let windowUUID: WindowUUID
    private let tabManager: TabManager
    private let prefs: Prefs
    private let telemetry: VPNClientTelemetry
    private let themeManager: ThemeManager
    private let featureFlagsProvider: FeatureFlagProviding
    private let onOpenURL: (URL) -> Void

    init(
        router: Router,
        windowUUID: WindowUUID,
        tabManager: TabManager,
        prefs: Prefs,
        telemetry: VPNClientTelemetry = DefaultVPNTelemetry(),
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        onOpenURL: @escaping (URL) -> Void
    ) {
        self.windowUUID = windowUUID
        self.tabManager = tabManager
        self.prefs = prefs
        self.telemetry = telemetry
        self.themeManager = themeManager
        self.featureFlagsProvider = featureFlagsProvider
        self.onOpenURL = onOpenURL
        super.init(router: router)
    }

    /// Whether the user still has to see the onboarding, wherever they are in the app.
    var isOnboardingPending: Bool {
        guard #available(iOS 27.2, *),
              featureFlagsProvider.isEnabled(.vpnFeature),
              featureFlagsProvider.isEnabled(.vpnOnboardingSheet)
        else { return false }
        return prefs.boolForKey(PrefsKeys.VPNSettings.onboardingSheetShown) != true
    }

    func shouldShow() -> Bool {
        guard let selectedTab = tabManager.selectedTab, !selectedTab.isFxHomeTab else { return false }
        return isOnboardingPending
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
        controller.sheetPresentationController?.detents = [.medium(), .large()]
        controller.sheetPresentationController?.prefersGrabberVisible = true

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
        if #available(iOS 27.2, *), let url = VPNSettingsViewController.learnMoreURL {
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
        let dataLimit = VPNHelpers.formatted(gigabytes: Double(VPNConstants.freeMonthlyDataLimitInGB))
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
                    imageName: StandardImageIdentifiers.ExtraLarge.globeMap,
                    title: .VPN.Onboarding.LocationsSubheading,
                    subtitle: .VPN.Onboarding.LocationsBody
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
