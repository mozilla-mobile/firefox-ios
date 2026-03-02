// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Delegate protocol for handling launch screen loading completion events
protocol LaunchFinishedLoadingDelegate: AnyObject {
    /// Called when a specific launch type should be displayed
    /// - Parameter launchType: The type of launch screen to display
    @MainActor
    func launchWith(launchType: LaunchType)

    /// Called when the browser should be launched directly (no onboarding screens)
    @MainActor
    func launchBrowser()

    /// Called when the launch order has been determined and is ready to be displayed
    @MainActor
    func finishedLoadingLaunchOrder()
}

/// ViewModel responsible for determining which launch screens to display at app startup
/// Manages the sequence of onboarding screens (terms of service, intro, update, survey)
@MainActor
class LaunchScreenViewModel {
    private let termsOfServiceManager: TermsOfServiceManager
    private let introScreenManager: IntroScreenManagerProtocol
    private let updateViewModel: UpdateViewModel
    private let surveySurfaceManager: SurveySurfaceManager
    private let profile: Profile

    /// Ordered list of launch screens to display. Empty array means no screens to show.
    private(set) var launchOrder: [LaunchType] = []

    /// Tracks whether loading has completed. Used to distinguish between "not loaded yet" and "loaded with no screens".
    private var hasFinishedLoading = false

    weak var delegate: LaunchFinishedLoadingDelegate?

    /// Initializes the launch screen view model
    /// - Parameters:
    ///   - windowUUID: The unique identifier for the window
    ///   - profile: User profile for accessing preferences (defaults to shared instance)
    ///   - messageManager: Manager for GleanPlumb messages (defaults to experiments messaging)
    ///   - onboardingModel: Onboarding model configuration (defaults to upgrade model)
    ///   - introScreenManager: Manager for intro screen logic (defaults to new instance)
    init(
        windowUUID: WindowUUID,
        profile: Profile = AppContainer.shared.resolve(),
        messageManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
        onboardingModel: OnboardingKitViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade),
        introScreenManager: IntroScreenManagerProtocol? = nil
    ) {
        self.profile = profile
        self.termsOfServiceManager = TermsOfServiceManager(prefs: profile.prefs)
        self.introScreenManager = introScreenManager ?? IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel, onboardingReason: .newUser)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility,
                                               windowUUID: windowUUID)
        self.surveySurfaceManager = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
    }

    /// Checks if the splash screen experiment has already been shown
    /// - Returns: True if the splash screen experiment has been shown, false otherwise
    func getSplashScreenExperimentHasShown() -> Bool {
        profile.prefs.boolForKey(PrefsKeys.splashScreenShownKey) ?? false
    }

    /// Marks the splash screen experiment as having been shown
    func setSplashScreenExperimentHasShown() {
        profile.prefs.setBool(true, forKey: PrefsKeys.splashScreenShownKey)
    }

    /// Starts loading and determining which launch screens to display
    /// - Parameter appVersion: Current app version (defaults to AppInfo.appVersion)
    func startLoading(appVersion: String = AppInfo.appVersion) {
        loadLaunchType(appVersion: appVersion)
    }

    /// Loads and displays the next launch type in the sequence
    /// If no more launch types remain, launches the browser directly
    func loadNextLaunchType() {
        // If loading hasn't finished yet, return early (don't call launchBrowser prematurely)
        guard hasFinishedLoading else {
            return
        }

        guard !launchOrder.isEmpty else {
            delegate?.launchBrowser()
            return
        }

        let launchType = launchOrder.removeFirst()
        delegate?.launchWith(launchType: launchType)
    }

    /// Determines which launch screens should be displayed based on app state
    /// - Parameter appVersion: Current app version
    private func loadLaunchType(appVersion: String) {
        var order: [LaunchType] = []

        if introScreenManager.shouldShowIntroScreen {
            if termsOfServiceManager.shouldShowScreen {
                order.append(.termsOfService(manager: termsOfServiceManager))
            }
            order.append(.intro(manager: introScreenManager))
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion),
                  updateViewModel.containsSyncableAccount() {
            order.append(.update(viewModel: updateViewModel))
        } else if surveySurfaceManager.shouldShowSurveySurface {
            order.append(.survey(manager: surveySurfaceManager))
        }

        self.launchOrder = order
        hasFinishedLoading = true

        if order.isEmpty {
            delegate?.launchBrowser()
        } else {
            delegate?.finishedLoadingLaunchOrder()
        }
    }
}
