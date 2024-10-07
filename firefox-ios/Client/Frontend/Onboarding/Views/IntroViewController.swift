// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux
import Shared
import UIKit

class IntroViewController: UIViewController,
                           OnboardingViewControllerProtocol,
                           Themeable,
                           Notifiable,
                           FeatureFlaggable,
                           StoreSubscriber {
    struct UX {
        static let closeButtonSize: CGFloat = 30
        static let closeHorizontalMargin: CGFloat = 24
        static let closeVerticalMargin: CGFloat = 20
        static let pageControlHeight: CGFloat = 40
    }

    typealias SubscriberStateType = OnboardingViewControllerState

    // MARK: - Properties
    var viewModel: OnboardingViewModelProtocol
    var windowUUID: WindowUUID
    var didFinishFlow: (() -> Void)?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var userDefaults: UserDefaultsInterface
    var hasRegisteredForDefaultBrowserNotification = false
    var currentWindowUUID: UUID? { windowUUID }
    weak var qrCodeNavigationHandler: QRCodeNavigationHandler?
    private var introViewControllerState: OnboardingViewControllerState?

    // MARK: - UI elements

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeOnboarding), for: .touchUpInside)
        button.accessibilityLabel = String.localizedStringWithFormat(
            .Onboarding.Welcome.CloseButtonAccessibilityLabel,
            AppName.shortName.rawValue
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.closeButton
    }

    lazy var pageController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll,
                                          navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self

        return pageVC
    }()

    lazy var pageControl: UIPageControl = .build { pageControl in
        pageControl.currentPage = 0
        pageControl.numberOfPages = self.viewModel.availableCards.count
        pageControl.isUserInteractionEnabled = false
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.pageControl
    }

    // MARK: Initializers
    init(
        viewModel: IntroViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        super.init(nibName: nil, bundle: nil)

        self.viewModel.setupViewControllerDelegates(with: self, for: windowUUID)
        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        populatePageController()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: View setup
    private func populatePageController() {
        if let firstViewController = viewModel.availableCards.first {
            pageController.setViewControllers([firstViewController],
                                              direction: .forward,
                                              animated: true,
                                              completion: nil)
        }
    }

    private func setupLayout() {
        setupPageController()
        if viewModel.isDismissable { setupCloseButton() }
    }

    private func setupPageController() {
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupCloseButton() {
        guard viewModel.isDismissable else { return }
        view.addSubview(closeButton)
        view.bringSubviewToFront(closeButton)
        view.accessibilityElements = [closeButton, pageController.view as Any, pageControl]

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeVerticalMargin),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeHorizontalMargin),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
        ])
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .onboardingViewController)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return OnboardingViewControllerState(appState: appState, uuid: uuid)
            })
        })
    }

    // Note: actual `store.unsubscribe()` is not strictly needed; Redux uses weak subscribers
    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .onboardingViewController)
        store.dispatch(action)
    }

    func newState(state: OnboardingViewControllerState) {
        ensureMainThread { [weak self] in
            guard let self else { return }

            introViewControllerState = state

            applyTheme()
        }
    }

    // MARK: - Button actions
    @objc
    func closeOnboarding() {
        guard let viewModel = viewModel as? IntroViewModel else { return }
        viewModel.saveHasSeenOnboarding()
        didFinishFlow?()
        viewModel.telemetryUtility.sendDismissOnboardingTelemetry(
            from: viewModel.availableCards[pageControl.currentPage].viewModel.name)
    }

    @objc
    func dismissSignInViewController() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func dismissPrivacyPolicyViewController() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            appDidEnterBackgroundNotification()
        default:
            break
        }
    }

    func registerForNotification() {
        if !hasRegisteredForDefaultBrowserNotification {
            setupNotifications(forObserver: self,
                               observing: [UIApplication.didEnterBackgroundNotification])
            hasRegisteredForDefaultBrowserNotification = true
        }
    }

    func appDidEnterBackgroundNotification() {
        let currentViewModel = viewModel.availableCards[pageControl.currentPage].viewModel
        guard currentViewModel.buttons.primary.action == .setDefaultBrowser
                || currentViewModel.buttons.secondary?.action == .setDefaultBrowser
        else { return }

        advance(
            numberOfPages: 1,
            from: currentViewModel.name,
            completionIfLastCard: { self.showNextPageCompletionForLastCard() })
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer2

        pageControl.currentPageIndicatorTintColor = theme.colors.actionPrimary
        pageControl.pageIndicatorTintColor = theme.colors.formSurfaceOff

//        viewModel.availableCards.forEach { $0.applyTheme() }
    }
}

// MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate
extension IntroViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC)
        else { return nil }

        pageControl.currentPage = index

        return getNextOnboardingCard(
            currentIndex: index,
            numberOfCardsToMove: 1,
            goForward: false
        )
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC)
        else { return nil }

        pageControl.currentPage = index

        return getNextOnboardingCard(
            currentIndex: index,
            numberOfCardsToMove: 1,
            goForward: true
        )
    }
}

// MARK: - OnboardingCardDelegate
extension IntroViewController: OnboardingCardDelegate {
    func handleBottomButtonActions(
        for action: OnboardingActions,
        from cardName: String,
        isPrimaryButton: Bool
    ) {
        viewModel.telemetryUtility.sendButtonActionTelemetry(
            from: cardName,
            with: action,
            and: isPrimaryButton)

        guard let introViewModel = viewModel as? IntroViewModel else { return }
        switch action {
        case .requestNotifications:
            introViewModel.chosenOptions.insert(.askForNotificationPermission)
            introViewModel.updateOnboardingUserActivationEvent()
            askForNotificationPermission(from: cardName)
        case .forwardOneCard:
            advance(numberOfPages: 1, from: cardName) {
                self.showNextPageCompletionForLastCard()
            }
        case .forwardTwoCard:
            advance(numberOfPages: 2, from: cardName) {
                self.showNextPageCompletionForLastCard()
            }
        case .forwardThreeCard:
            advance(numberOfPages: 3, from: cardName) {
                self.showNextPageCompletionForLastCard()
            }
        case .syncSignIn:
            introViewModel.chosenOptions.insert(.syncSignIn)
            introViewModel.updateOnboardingUserActivationEvent()
            let fxaPrams = FxALaunchParams(entrypoint: .introOnboarding, query: [:])
            presentSignToSync(
                windowUUID: windowUUID,
                with: fxaPrams,
                selector: #selector(dismissSignInViewController),
                completion: {
                    self.advance(numberOfPages: 1, from: cardName) {
                        self.showNextPageCompletionForLastCard()
                    }
                },
                qrCodeNavigationHandler: qrCodeNavigationHandler
            )
        case .setDefaultBrowser:
            introViewModel.chosenOptions.insert(.setAsDefaultBrowser)
            introViewModel.updateOnboardingUserActivationEvent()
            registerForNotification()
            DefaultApplicationHelper().openSettings()
        case .openInstructionsPopup:
            presentDefaultBrowserPopup(
                windowUUID: windowUUID,
                from: cardName,
                completionIfLastCard: { self.showNextPageCompletionForLastCard() })
        case .readPrivacyPolicy:
            presentPrivacyPolicy(
                windowUUID: windowUUID,
                from: cardName,
                selector: #selector(dismissPrivacyPolicyViewController))
        case .openIosFxSettings:
            DefaultApplicationHelper().openSettings()
            advance(numberOfPages: 1, from: cardName) {
                self.showNextPageCompletionForLastCard()
            }
        case .endOnboarding:
            closeOnboarding()
        }
    }

    func handleMultipleChoiceButtonActions(
        for action: OnboardingMultipleChoiceAction,
        from cardName: String
    ) {
        switch action {
        case .themeDark:
            turnSystemTheme(on: false)
            let action = ThemeSettingsViewAction(manualThemeType: .dark,
                                                 windowUUID: windowUUID,
                                                 actionType: ThemeSettingsViewActionType.switchManualTheme)
            store.dispatch(action)
        case .themeLight:
            turnSystemTheme(on: false)
            let action = ThemeSettingsViewAction(manualThemeType: .light,
                                                 windowUUID: windowUUID,
                                                 actionType: ThemeSettingsViewActionType.switchManualTheme)
            store.dispatch(action)
        case .themeSystemDefault:
            turnSystemTheme(on: true)
        case .toolbarBottom:
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
        case .toolbarTop:
            featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.top)
        }
        viewModel.telemetryUtility.sendMultipleChoiceButtonActionTelemetry(
            from: cardName,
            with: action
        )
    }

    private func turnSystemTheme(on state: Bool) {
        let action = ThemeSettingsViewAction(useSystemAppearance: state,
                                             windowUUID: windowUUID,
                                             actionType: ThemeSettingsViewActionType.toggleUseSystemAppearance)
        store.dispatch(action)
    }

    func sendCardViewTelemetry(from cardName: String) {
        viewModel.telemetryUtility.sendCardViewTelemetry(from: cardName)
    }

    private func showNextPageCompletionForLastCard() {
        guard let viewModel = viewModel as? IntroViewModel else { return }
        viewModel.saveHasSeenOnboarding()
        didFinishFlow?()
    }

    private func askForNotificationPermission(from cardName: String) {
        let notificationManager = NotificationManager()

        notificationManager.requestAuthorization { [weak self] granted, error in
            guard error == nil, let self = self else { return }

            DispatchQueue.main.async {
                if granted {
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.SyncNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.SyncNotifications)
                    }
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
                    }

                    NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
                }
                self.advance(numberOfPages: 1, from: cardName) {
                    self.showNextPageCompletionForLastCard()
                }
            }
        }
    }
}

// MARK: UIViewController setup
extension IntroViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}
