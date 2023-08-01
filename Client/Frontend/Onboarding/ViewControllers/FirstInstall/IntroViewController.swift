// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common

class IntroViewController: UIViewController,
                           OnboardingViewControllerProtocol,
                           Themeable,
                           Notifiable {
    struct UX {
        static let closeButtonSize: CGFloat = 30
        static let closeHorizontalMargin: CGFloat = 24
        static let closeVerticalMargin: CGFloat = 20
        static let pageControlHeight: CGFloat = 40
    }

    // MARK: - Properties
    var viewModel: OnboardingViewModelProtocol
    var didFinishFlow: (() -> Void)?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var userDefaults: UserDefaultsInterface
    var hasRegisteredForDefaultBrowserNotification = false

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeOnboarding), for: .touchUpInside)
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
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        super.init(nibName: nil, bundle: nil)

        self.viewModel.setupViewControllerDelegates(with: self)
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

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeVerticalMargin),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeHorizontalMargin),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
        ])
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

        showNextPage(
            from: currentViewModel.name,
            completionIfLastCard: { self.showNextPageCompletionForLastCard() })
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.currentTheme
        view.backgroundColor = theme.colors.layer2

        pageControl.currentPageIndicatorTintColor = theme.colors.actionPrimary
        pageControl.pageIndicatorTintColor = theme.colors.actionSecondary

        viewModel.availableCards.forEach { $0.applyTheme() }
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
        return getNextOnboardingCard(index: index, goForward: false)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC)
        else { return nil }

        pageControl.currentPage = index
        return getNextOnboardingCard(index: index, goForward: true)
    }
}

// MARK: - OnboardingCardDelegate
extension IntroViewController: OnboardingCardDelegate {
    func handleButtonPress(
        for action: OnboardingActions,
        from cardName: String,
        isPrimaryButton: Bool
    ) {
        viewModel.telemetryUtility.sendButtonActionTelemetry(
            from: cardName,
            with: action,
            and: isPrimaryButton)

        switch action {
        case .requestNotifications:
            askForNotificationPermission(from: cardName)
        case .nextCard:
            showNextPage(from: cardName) {
                self.showNextPageCompletionForLastCard()
            }
        case .syncSignIn:
            let fxaPrams = FxALaunchParams(entrypoint: .introOnboarding, query: [:])
            presentSignToSync(
                with: fxaPrams,
                selector: #selector(dismissSignInViewController)
            ) {
                self.showNextPage(from: cardName) {
                    self.showNextPageCompletionForLastCard()
                }
            }
        case .setDefaultBrowser:
            registerForNotification()
            DefaultApplicationHelper().openSettings()
        case .openInstructionsPopup:
            presentDefaultBrowserPopup(
                from: cardName,
                completionIfLastCard: { self.showNextPageCompletionForLastCard() })
        case .readPrivacyPolicy:
            presentPrivacyPolicy(
                from: cardName,
                selector: #selector(dismissPrivacyPolicyViewController))
        }
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
                self.showNextPage(from: cardName) {
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
