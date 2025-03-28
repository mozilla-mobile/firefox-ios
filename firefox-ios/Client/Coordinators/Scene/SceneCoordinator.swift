// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator,
                        LaunchCoordinatorDelegate,
                        LaunchFinishedLoadingDelegate,
                        FeatureFlaggable {
    var window: UIWindow?
    var windowUUID: WindowUUID { reservedWindowUUID.uuid }
    private var isDeeplinkOptimizationRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.deeplinkOptimizationRefactor, checking: .buildOnly)
    }
    private let screenshotService: ScreenshotService
    private let sceneContainer: SceneContainer
    private let windowManager: WindowManager
    private let reservedWindowUUID: ReservedWindowUUID

    init(scene: UIScene,
         sceneSetupHelper: SceneSetupHelper = SceneSetupHelper(),
         screenshotService: ScreenshotService = ScreenshotService(),
         sceneContainer: SceneContainer = SceneContainer(),
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        // Note: this is where we singularly decide the UUID for this specific iOS browser window (UIScene).
        // The logic is handled by `reserveNextAvailableWindowUUID`, but this is the point at which a window's UUID
        // is set; this same UUID will be injected throughout several of the window's related components
        // such as its TabManager instance, which also has the window UUID property as a convenience.
        let isIpad = (UIDevice.current.userInterfaceIdiom == .pad)
        let reserved = windowManager.reserveNextAvailableWindowUUID(isIpad: isIpad)
        self.reservedWindowUUID = reserved
        self.window = sceneSetupHelper.configureWindowFor(scene,
                                                          windowUUID: reserved.uuid,
                                                          screenshotServiceDelegate: screenshotService)
        self.screenshotService = screenshotService
        self.sceneContainer = sceneContainer
        self.windowManager = windowManager

        let navigationController = sceneSetupHelper.createNavigationController()
        let router = DefaultRouter(navigationController: navigationController)
        super.init(router: router)

        logger.log("SceneCoordinator init completed (UUID: \(reserved.uuid))", level: .debug, category: .lifecycle)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func start() {
        router.setRootViewController(sceneContainer, hideBar: true)

        let launchScreenVC = LaunchScreenViewController(windowUUID: windowUUID, coordinator: self)
        router.push(launchScreenVC, animated: false)
    }

    override func canHandle(route: Route) -> Bool {
        switch route {
        case .action(action: .showIntroOnboarding):
            return canShowIntroOnboarding()
        default:
            return false
        }
    }

    override func handle(route: Route) {
        switch route {
        case .action(action: .showIntroOnboarding):
            showIntroOnboardingIfNeeded()
        default:
            break
        }
    }

    private func canShowIntroOnboarding() -> Bool {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        return launchType.canLaunch(fromType: .SceneCoordinator)
    }

    private func showIntroOnboardingIfNeeded() {
        let profile: Profile = AppContainer.shared.resolve()
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        if launchType.canLaunch(fromType: .SceneCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        guard launchType.canLaunch(fromType: .SceneCoordinator) else {
            startBrowser(with: launchType)
            return
        }

        startLaunch(with: launchType)
    }

    func launchBrowser() {
        startBrowser(with: nil)
    }

    // No implementation needed as LaunchScreenViewController is not calling this coordinator method
    func finishedLoadingLaunchOrder() { }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        logger.log("Launching with launchtype \(launchType)",
                   level: .info,
                   category: .coordinator)

        let launchCoordinator = LaunchCoordinator(router: router, windowUUID: windowUUID)
        launchCoordinator.parentCoordinator = self
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType)
    }

    private func startBrowser(with launchType: LaunchType?) {
        guard !childCoordinators.contains(where: { $0 is BrowserCoordinator }) else { return }

        logger.log("Starting browser with launchtype \(String(describing: launchType))",
                   level: .info,
                   category: .coordinator)

        let tabManager = TabManagerImplementation(profile: AppContainer.shared.resolve(),
                                                  uuid: reservedWindowUUID)
        let browserCoordinator = BrowserCoordinator(router: router,
                                                    screenshotService: screenshotService,
                                                    tabManager: tabManager)

        let windowInfo = AppWindowInfo(tabManager: tabManager, sceneCoordinator: self)
        windowManager.newBrowserWindowConfigured(windowInfo, uuid: windowUUID)

        add(child: browserCoordinator)
        browserCoordinator.start(with: launchType)

        if let savedRoute {
            browserCoordinator.findAndHandle(route: savedRoute)
            // In the case we have saved route it means we are starting the browser with a deeplink.
            // A saved route is present when findAndHandle is called on the SceneCoordinator and BrowserCoordinator
            // is not in the hierarchy yet.
            guard isDeeplinkOptimizationRefactorEnabled,
                  !AppEventQueue.hasSignalled(.recordStartupTimeOpenDeeplinkComplete),
                  !AppEventQueue.hasSignalled(.recordStartupTimeOpenDeeplinkCancelled) else { return }
            AppEventQueue.signal(event: .recordStartupTimeOpenDeeplinkComplete)
        }
    }

    // MARK: - LaunchCoordinatorDelegate
    func didFinishTermsOfService(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true)
        remove(child: coordinator)
    }

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true)
        remove(child: coordinator)
        startBrowser(with: nil)
    }
}
