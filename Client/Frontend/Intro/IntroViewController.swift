// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

class IntroViewController: UIViewController, OnViewDismissable {
    var onViewDismissed: (() -> Void)?
    var viewModel: IntroViewModel
    var onboardingPages = [OnboardingCardViewController]()

    // MARK: - Var related to onboarding
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        let closeImage = UIImage(named: ImageIdentifiers.closeLargeButton)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(closeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeOnboarding), for: .touchUpInside)
        return button
    }()

    private lazy var pageController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        return pageVC
    }()

    private lazy var pageControl: UIPageControl = .build { pageControl in
        pageControl.currentPage = 0
        pageControl.numberOfPages = self.viewModel.enabledCards.count
        pageControl.currentPageIndicatorTintColor = UIColor.Photon.Blue50
        pageControl.pageIndicatorTintColor = UIColor.Photon.LightGrey40
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

        view.backgroundColor = .lightGray
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
        var index = 0
        self.viewModel.enabledCards.forEach { card in
            let cardViewModel = viewModel.getCardViewModel(index: index)
            let viewController = OnboardingCardViewController(viewModel: cardViewModel)
            onboardingPages.append(viewController)
            index += 1
        }

        if let firstViewController = onboardingPages.first {
            pageController.setViewControllers([firstViewController],
                                                  direction: .forward,
                                                  animated: true,
                                                  completion: nil)
        }
    }

    private func setupLayout() {
        view.addSubviews(pageControl, closeButton)

        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)

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

//        onboardingCard.nextClosure = {
//            guard self.viewModel.currentCard != .signSync else {
//                self.didFinishClosure?(self, nil)
//                return
//            }
//
//            self.showNextCard()
//        }
//
//        onboardingCard.primaryActionClosure = {
//            switch self.viewModel.currentCard {
//            case .welcome:
//                self.showNextCard()
//            default:
//                break
//            }
//        }
    }

    @objc private func closeOnboarding() {
        didFinishClosure?(self, nil)
    }

    private func showNextOnboardingCard(index: Int) -> OnboardingCardViewController? {
        guard index < onboardingPages.count else { return nil }

        let cardViewModel = viewModel.getCardViewModel(index: index)
        return OnboardingCardViewController(viewModel: cardViewModel)
    }
}

extension IntroViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }

    private func getIndex(viewController: OnboardingCardViewController) -> Int? {
        let cardType = viewController.viewModel.cardType

        return viewModel.enabledCards.firstIndex(of: cardType)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let onboardingVC = viewController as? OnboardingCardViewController,
              let index = getIndex(viewController: onboardingVC) else {
              return nil
        }

        if index == viewModel.enabledCards.count - 1 { return nil }

        pageControl.currentPage = index + 1
        return showNextOnboardingCard(index: index + 1)
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
