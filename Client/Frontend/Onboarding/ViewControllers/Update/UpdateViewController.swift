// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common

class UpdateViewController: UIViewController, OnboardingViewControllerProtocol, Themeable {
    // Update view UX constants
    struct UX {
        static let closeButtonTopPadding: CGFloat = 32
        static let closeButtonRightPadding: CGFloat = 16
        static let closeButtonSize: CGFloat = 30
        static let pageControlHeight: CGFloat = 40
    }

    // MARK: - Properties
    var viewModel: OnboardingViewModelProtocol
    var didFinishFlow: (() -> Void)?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: ImageIdentifiers.bottomSheetClose), for: .normal)
        button.addTarget(self, action: #selector(self.closeUpdate), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.closeButton
    }

    lazy var pageController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    lazy var pageControl: UIPageControl = .build { pageControl in
        pageControl.currentPage = 0
        pageControl.numberOfPages = self.viewModel.availableCards.count
        pageControl.currentPageIndicatorTintColor = UIColor.Photon.Blue50
        pageControl.pageIndicatorTintColor = UIColor.Photon.LightGrey40
        pageControl.isUserInteractionEnabled = false
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.pageControl
    }

    // MARK: - Initializers
    init(
        viewModel: UpdateViewModel,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.setupViewControllerDelegates(with: self)
        setupView()
        applyTheme()
        listenForThemeChange(view)
    }

    // MARK: View setup
    private func setupView() {
        guard let viewModel = viewModel as? UpdateViewModel else { return }
        view.backgroundColor = UIColor.legacyTheme.browser.background
        if viewModel.shouldShowSingleCard {
            setupSingleInfoCard()
        } else {
            setupMultipleCards()
            setupMultipleCardsConstraints()
        }
    }

    private func setupSingleInfoCard() {
//        guard let viewModel = viewModel.getCardViewModel(cardType: viewModel.enabledCards[0]) else { return }
//
//        let cardViewController = OnboardingCardViewController(viewModel: viewModel,
//                                                              delegate: self)
//        view.addSubview(closeButton)
//        addChild(cardViewController)
//        view.addSubview(cardViewController.view)
//        cardViewController.didMove(toParent: self)
//        view.bringSubviewToFront(closeButton)
//
//        NSLayoutConstraint.activate([
//            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonTopPadding),
//            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonRightPadding),
//            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
//            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize)
//        ])
    }

    private func setupMultipleCards() {
//        if let firstViewController = informationCards.first {
//            pageController.setViewControllers([firstViewController],
//                                              direction: .forward,
//                                              animated: true,
//                                              completion: nil)
//        }
    }

    private func setupMultipleCardsConstraints() {
//        addChild(pageController)
//        view.addSubview(pageController.view)
//        pageController.didMove(toParent: self)
//        view.addSubviews(pageControl, closeButton)
//
//        NSLayoutConstraint.activate([
//            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonTopPadding),
//            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonRightPadding),
//            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
//            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
//        ])
    }

    // Button Actions
    @objc
    private func closeUpdate() {
        didFinishFlow?()
//        viewModel.sendCloseButtonTelemetry(index: pageControl.currentPage)
    }

    @objc
    func dismissSignInViewController() {
        dismiss(animated: true, completion: nil)
        closeUpdate()
    }

    @objc
    func dismissPrivacyPolicyViewController() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Theme
    func applyTheme() {
//        guard !viewModel.shouldShowSingleCard else { return }

        let theme = themeManager.currentTheme
        pageControl.currentPageIndicatorTintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer2

        viewModel.availableCards.forEach { $0.applyTheme() }
    }
}

// MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate
extension UpdateViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC) else {
              return nil
        }

        pageControl.currentPage = index
        return getNextOnboardingCard(index: index, goForward: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC) else {
              return nil
        }

        pageControl.currentPage = index
        return getNextOnboardingCard(index: index, goForward: true)
    }
}

extension UpdateViewController: OnboardingCardDelegate {
    func handleButtonPress(
        for action: OnboardingActions,
        from cardNamed: String
    ) {
        switch action {
        case .nextCard:
            showNextPage(from: cardNamed) {
                self.didFinishFlow?()
            }
        case .syncSignIn:
            let fxaParams = FxALaunchParams(entrypoint: .updateOnboarding, query: [:])
            presentSignToSync(fxaParams)
        case .readPrivacyPolicy:
            showPrivacyPolicy(
                from: cardNamed,
                selector: #selector(dismissPrivacyPolicyViewController)
            ) {
                self.closeUpdate()
            }
        default:
            break
        }
    }

    private func presentSignToSync(
        _ fxaOptions: FxALaunchParams,
        flowType: FxAPageType = .emailLoginFlow,
        referringPage: ReferringPage = .onboarding
    ) {
        guard let viewModel = viewModel as? UpdateViewModel else { return }

        let singInSyncVC = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            fxaOptions,
            flowType: flowType,
            referringPage: referringPage,
            profile: viewModel.profile)

        let controller: DismissableNavigationViewController
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissSignInViewController))
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        buttonItem.tintColor = theme == .dark ? UIColor.legacyTheme.homePanel.activityStreamHeaderButton : UIColor.Photon.Blue50
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        controller = DismissableNavigationViewController(rootViewController: singInSyncVC)

        controller.onViewDismissed = {
            self.closeUpdate()
        }

        self.present(controller, animated: true)
    }
}

// MARK: UIViewController setup
extension UpdateViewController {
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
