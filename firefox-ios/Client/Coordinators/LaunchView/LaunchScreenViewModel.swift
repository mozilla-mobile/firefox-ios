// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol LaunchFinishedLoadingDelegate: AnyObject {
    func launchWith(launchType: LaunchType)
    func launchBrowser()
}

class LaunchScreenViewModel: FeatureFlaggable {
    private var profile: Profile
    private var introScreenManager: IntroScreenManager
    private var updateViewModel: UpdateViewModel
    private var surveySurfaceManager: SurveySurfaceManager

    private let nimbusSplashScreenFeatureLayer = NimbusSplashScreenFeatureLayer()
    private var splashScreenTask: Task<Void, Never>?
    private var hasExperimentsLoaded = false

    weak var delegate: LaunchFinishedLoadingDelegate?

    init(profile: Profile = AppContainer.shared.resolve(),
         messageManager: GleanPlumbMessageManagerProtocol = Experiments.messaging,
         onboardingModel: OnboardingViewModel = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .upgrade)) {
        self.profile = profile
        self.introScreenManager = IntroScreenManager(prefs: profile.prefs)
        let telemetryUtility = OnboardingTelemetryUtility(with: onboardingModel)
        self.updateViewModel = UpdateViewModel(profile: profile,
                                               model: onboardingModel,
                                               telemetryUtility: telemetryUtility)
        self.surveySurfaceManager = SurveySurfaceManager(and: messageManager)

        if featureFlags.isFeatureEnabled(.splashScreen, checking: .buildOnly) {
            Task {
                await fetchNimbusExperiments()
            }
        }
    }

    func startLoading(appVersion: String = AppInfo.appVersion) async {
        await loadLaunchType(appVersion: appVersion)
    }

    /// Delay start up and continue to show splash screen up to a maximum duration to ensure Nimbus 
    /// experiments are loaded on first launch. Skip the delay start if experiments are already successfully
    /// loaded at this point.
    func startSplashScreenExperiment() async {
        guard featureFlags.isFeatureEnabled(.splashScreen, checking: .buildOnly), !hasExperimentsLoaded else { return }
        await delayStart()
    }

    private func delayStart() async {
        let position: Int = nimbusSplashScreenFeatureLayer.maximumDurationMs
        splashScreenTask?.cancel()
        splashScreenTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(position * 1_000_000))
        }
        await splashScreenTask?.value
    }

    private func fetchNimbusExperiments() async {
        Experiments.intialize()

        NotificationCenter.default.addObserver(
            forName: .nimbusExperimentsFetched,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.splashScreenTask?.cancel()
            self?.hasExperimentsLoaded = true
        }
    }

    private func loadLaunchType(appVersion: String) async {
        var launchType: LaunchType?
        if introScreenManager.shouldShowIntroScreen {
            launchType = .intro(manager: introScreenManager)
        } else if updateViewModel.shouldShowUpdateSheet(appVersion: appVersion),
                  await updateViewModel.hasSyncableAccount() {
            launchType = .update(viewModel: updateViewModel)
        } else if surveySurfaceManager.shouldShowSurveySurface {
            launchType = .survey(manager: surveySurfaceManager)
        }

        if let launchType = launchType {
            self.delegate?.launchWith(launchType: launchType)
        } else {
            self.delegate?.launchBrowser()
        }
    }
}
