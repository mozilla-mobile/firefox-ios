// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

// TODO:
// 2- Bring back old onboarding just in case
// 3- Add debug option??
// 4- Check indicator failing from 2 to 3 and going backwards sometimes

class IntroViewController: UIViewController, OnViewDismissable {
    var onViewDismissed: (() -> Void)?
    var viewModel: IntroViewModel

    // MARK: - Var related to onboarding
    private lazy var closeButton: UIButton = .build { button in
        let closeImage = UIImage(named: ImageIdentifiers.closeLargeButton)
        button.setImage(closeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(self.closeOnboarding), for: .touchUpInside)
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
    }

    // Closure delegate
    var didFinishClosure: ((IntroViewController, FxAPageType?) -> Void)?

    // MARK: Initializer
    init(viewModel: IntroViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.theme.browser.background
        setupPageController()
        setupLayout()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    // MARK: View setup
    private func setupPageController() {
        if let firstViewController = showNextOnboardingCard(index: 0) {
            pageController.setViewControllers([firstViewController],
                                                  direction: .forward,
                                                  animated: true,
                                                  completion: nil)
        }
    }

    private func setupLayout() {
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        view.addSubviews(pageControl, closeButton)

        NSLayoutConstraint.activate([
            pageControl.heightAnchor.constraint(equalToConstant: 40),
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func closeOnboarding() {
        didFinishClosure?(self, nil)
    }

    private func showNextOnboardingCard(index: Int) -> OnboardingCardViewController? {
        guard index < viewModel.enabledCards.count else { return nil }

        let cardViewModel = viewModel.getCardViewModel(index: index)

        if index == viewModel.enabledCards.firstIndex(of: .wallpapers) {
            return WallpaperCardViewController(viewModel: cardViewModel, delegate: self)
        } else {
            return OnboardingCardViewController(viewModel: cardViewModel, delegate: self)
        }
    }

    private func getCardIndex(viewController: OnboardingCardViewController) -> Int? {
        let cardType = viewController.viewModel.cardType

        return viewModel.enabledCards.firstIndex(of: cardType)
    }

    private func moveToNextPage(cardType: IntroViewModel.OnboardingCards) {
        if let nextViewController = showNextOnboardingCard(index: cardType.rawValue + 1) {
            pageControl.currentPage = cardType.rawValue + 1
            pageController.setViewControllers([nextViewController], direction: .forward, animated: true)
        }
    }
}

// MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate
extension IntroViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getCardIndex(viewController: onboardingVC) else {
              return nil
        }

        if index == viewModel.enabledCards.count - 1 { return nil }
        return showNextOnboardingCard(index: index + 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        let index = previousViewControllers.count
        guard completed, index != viewModel.enabledCards.count else { return }

        pageControl.currentPage = index
    }
}

extension IntroViewController: OnboardingCardDelegate {
    func showNextPage(_ cardType: IntroViewModel.OnboardingCards) {
        guard cardType != viewModel.enabledCards.last else {
            self.didFinishClosure?(self, nil)
            return
        }

        moveToNextPage(cardType: cardType)
    }

    func primaryAction(_ cardType: IntroViewModel.OnboardingCards) {
        switch cardType {
        case .welcome, .wallpapers:
            moveToNextPage(cardType: cardType)
        case .signSync:
            didFinishClosure?(self, .emailLoginFlow)
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
