/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

protocol OnboardingViewControllerProtocol {
    var didFinishClosure: (() -> Void)? { get }

    func getNextOnboardingCard(index: Int, goForward: Bool) -> OnboardingCardViewController?
    func moveToNextPage(cardType: IntroViewModel.InformationCards)
    func getCardIndex(viewController: OnboardingCardViewController) -> Int?
    func showNextPage(_ cardType: IntroViewModel.InformationCards)
}

class UpdateViewController: UIViewController, OnboardingViewControllerProtocol {

    // Update view UX constants
    struct UX {
        static let closeButtonTopPadding: CGFloat = 32
        static let closeButtonRightPadding: CGFloat = 16
        static let closeButtonSize: CGFloat = 32
        static let pageControlHeight: CGFloat = 40
        static let pageControlBottomPadding: CGFloat = 8
    }

    // Public constants 
    var viewModel: UpdateViewModel
    var didFinishClosure: (() -> Void)?
    private var informationCards = [OnboardingCardViewController]()

    // MARK: - Private vars
    private lazy var backgroundImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.upgradeBackground)
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.backgroundImage
    }

    internal lazy var closeButton: UIButton = .build { button in
        let closeImage = UIImage(named: ImageIdentifiers.upgradeCloseButton)
        button.setImage(closeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(self.dismissUpdate), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.closeButton
    }

    private lazy var pageController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    private lazy var pageControl: UIPageControl = .build { pageControl in
        pageControl.currentPage = 0
        pageControl.numberOfPages = self.viewModel.enabledCards.count
        pageControl.currentPageIndicatorTintColor = UIColor.Photon.Blue50
        pageControl.pageIndicatorTintColor = UIColor.Photon.LightGrey40
        pageControl.isUserInteractionEnabled = false
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Upgrade.pageControl
    }

    init(viewModel: UpdateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    // MARK: View setup
    private func setupView() {
        view.backgroundColor = UIColor.theme.browser.background
        if viewModel.shouldShowSingleCard {
            setupSingleInfoCard()
        } else {
            setupMultipleCards()
            setupMultipleCardsConstraints()
        }
    }

    private func setupSingleInfoCard() {
        guard let viewModel = viewModel.getCardViewModel(cardType: viewModel.enabledCards[0]) else { return }

        let cardViewController = OnboardingCardViewController(viewModel: viewModel,
                                                              delegate: self)
        view.addSubviews(backgroundImageView, closeButton)
        addChild(cardViewController)
        view.addSubview(cardViewController.view)
        cardViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonTopPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonRightPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonTopPadding),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupMultipleCards() {
        // Create onboarding card views
        var cardViewController: OnboardingCardViewController

        for cardType in viewModel.enabledCards {
            if let viewModel = viewModel.getCardViewModel(cardType: cardType) {
                cardViewController = OnboardingCardViewController(viewModel: viewModel,
                                                                      delegate: self)
                informationCards.append(cardViewController)
            }
        }

        if let firstViewController = informationCards.first {
            pageController.setViewControllers([firstViewController],
                                              direction: .forward,
                                              animated: true,
                                              completion: nil)
        }
    }

    private func setupMultipleCardsConstraints() {
        view.addSubview(backgroundImageView)
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        view.addSubviews(pageControl, closeButton)

        NSLayoutConstraint.activate([
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                constant: -UX.pageControlBottomPadding),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonTopPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonRightPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // Button Actions
    @objc private func dismissUpdate() {
        didFinishClosure?()
        viewModel.sendCloseButtonTelemetry(index: pageControl.currentPage)
    }

    func getNextOnboardingCard(index: Int, goForward: Bool) -> OnboardingCardViewController? {
        guard let index = viewModel.getNextIndex(currentIndex: index, goForward: goForward) else { return nil }

        return informationCards[index]
    }

    // Used to programmatically set the pageViewController to show next card
    func moveToNextPage(cardType: IntroViewModel.InformationCards) {
        if let nextViewController = getNextOnboardingCard(index: cardType.position, goForward: true) {
            pageControl.currentPage = cardType.position + 1
            pageController.setViewControllers([nextViewController], direction: .forward, animated: false)
        }
    }

    // Due to restrictions with PageViewController we need to get the index of the current view controller
    // to calculate the next view controller
    func getCardIndex(viewController: OnboardingCardViewController) -> Int? {
        let cardType = viewController.viewModel.cardType

        guard let index = viewModel.enabledCards.firstIndex(of: cardType) else { return nil }

        return index
    }

    private func presentSignToSync(_ fxaOptions: FxALaunchParams? = nil,
                                   flowType: FxAPageType = .emailLoginFlow,
                                   referringPage: ReferringPage = .onboarding) {

        let singInSyncVC = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            fxaOptions,
            flowType: flowType,
            referringPage: referringPage,
            profile: viewModel.profile)

        let controller: DismissableNavigationViewController
        let buttonItem = UIBarButtonItem(title: .SettingsSearchDoneButton,
                                         style: .plain,
                                         target: self,
                                         action: #selector(dismissSignInViewController))
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        controller = DismissableNavigationViewController(rootViewController: singInSyncVC)
        self.present(controller, animated: true)
    }

    @objc func dismissSignInViewController() {
        self.dismiss(animated: true, completion: nil)
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
    func showNextPage(_ cardType: IntroViewModel.InformationCards) {
        guard cardType != viewModel.enabledCards.last else {
            self.didFinishClosure?()
            return
        }

        moveToNextPage(cardType: cardType)
    }

    func primaryAction(_ cardType: IntroViewModel.InformationCards) {
        switch cardType {
        case .updateWelcome:
            showNextPage(cardType)
        case .updateSignSync:
            presentSignToSync()
        default:
            break
        }
    }

    // Extra step to make sure pageControl.currentPage is the right index card
    // because UIPageViewControllerDataSource call fails
    func pageChanged(_ cardType: IntroViewModel.InformationCards) {
        if let cardIndex = viewModel.positionForCard(cardType: cardType),
           cardIndex != pageControl.currentPage {
            pageControl.currentPage = cardIndex
        }
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
