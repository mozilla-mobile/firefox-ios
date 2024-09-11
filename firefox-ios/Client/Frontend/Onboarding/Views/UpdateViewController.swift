// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared
import Common

class UpdateViewController: UIViewController,
                            OnboardingViewControllerProtocol,
                            Themeable {
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
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    weak var qrCodeNavigationHandler: QRCodeNavigationHandler?

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeUpdate), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.closeButton
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
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.pageControl
    }

    // MARK: - Initializers
    init(
        viewModel: UpdateViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)

        self.viewModel.setupViewControllerDelegates(with: self, for: windowUUID)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        applyTheme()
        listenForThemeChange(view)
    }

    // MARK: View setup
    private func setupView() {
        guard let viewModel = viewModel as? UpdateViewModel else { return }

        if viewModel.shouldShowSingleCard {
            setupSingleInfoCard()
        } else {
            setupMultipleCards()
            setupMultipleCardsConstraints()
        }

        if viewModel.isDismissable { setupCloseButton() }
    }

    private func setupSingleInfoCard() {
        guard let cardViewController = viewModel.availableCards.first else { return }

        addChild(cardViewController)
        view.addSubview(cardViewController.view)
        cardViewController.didMove(toParent: self)
    }

    private func setupMultipleCards() {
        if let firstViewController = viewModel.availableCards.first {
            pageController.setViewControllers([firstViewController],
                                              direction: .forward,
                                              animated: true,
                                              completion: nil)
        }
    }

    private func setupMultipleCardsConstraints() {
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
            closeButton.topAnchor.constraint(equalTo: view.topAnchor,
                                             constant: UX.closeButtonTopPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeButtonRightPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize)
        ])
    }

    // Button Actions
    @objc
    private func closeUpdate() {
        didFinishFlow?()
        viewModel.telemetryUtility.sendDismissOnboardingTelemetry(
            from: viewModel.availableCards[pageControl.currentPage].viewModel.name)
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

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer2

        viewModel.availableCards.forEach { $0.applyTheme() }

        guard let viewModel = viewModel as? UpdateViewModel,
              !viewModel.shouldShowSingleCard
        else { return }
        pageControl.currentPageIndicatorTintColor = theme.colors.actionPrimary
        pageControl.pageIndicatorTintColor = theme.colors.formSurfaceOff
    }
}

// MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate
extension UpdateViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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

extension UpdateViewController: OnboardingCardDelegate {
    func handleBottomButtonActions(
        for action: OnboardingActions,
        from cardName: String,
        isPrimaryButton: Bool
    ) {
        viewModel.telemetryUtility.sendButtonActionTelemetry(
            from: cardName,
            with: action,
            and: isPrimaryButton)

        switch action {
        case .forwardOneCard:
            advance(numberOfPages: 1, from: cardName) {
                self.didFinishFlow?()
            }
        case .forwardTwoCard:
            advance(numberOfPages: 2, from: cardName) {
                self.didFinishFlow?()
            }
        case .forwardThreeCard:
            advance(numberOfPages: 3, from: cardName) {
                self.didFinishFlow?()
            }
        case .syncSignIn:
            let fxaParams = FxALaunchParams(entrypoint: .updateOnboarding, query: [:])
            presentSignToSync(
                windowUUID: windowUUID,
                with: fxaParams,
                selector: #selector(dismissSignInViewController),
                completion: {
                    self.closeUpdate()
                },
                qrCodeNavigationHandler: qrCodeNavigationHandler
            )
        case .readPrivacyPolicy:
            presentPrivacyPolicy(
                windowUUID: windowUUID,
                from: cardName,
                selector: #selector(dismissPrivacyPolicyViewController))
        case .openInstructionsPopup:
            presentDefaultBrowserPopup(
                windowUUID: windowUUID,
                from: cardName,
                completionIfLastCard: { self.closeUpdate() })
        case .endOnboarding:
            closeUpdate()
        default:
            break
        }
    }

    func handleMultipleChoiceButtonActions(
        for action: OnboardingMultipleChoiceAction,
        from cardName: String
    ) {
        // There is no multiple choice actions for updating
    }

    func sendCardViewTelemetry(from cardName: String) {
        viewModel.telemetryUtility.sendCardViewTelemetry(from: cardName)
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
