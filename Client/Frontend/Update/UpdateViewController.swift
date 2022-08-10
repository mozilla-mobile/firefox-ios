/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

class UpdateViewController: UIViewController {

    // Update view UX constants
    struct UX {
        static let closeButtonPadding: CGFloat = 24
        static let closeButtonSize: CGFloat = 30
        static let pageControlHeight: CGFloat = 40
        static let pageControlBottomPadding: CGFloat = 8
    }

    // Public constants 
    var viewModel: UpdateViewModel
    private var informationCards = [OnboardingCardViewController]()
    static let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal

    // MARK: - Private vars
//    private var fxTextThemeColour: UIColor {
//        // For dark theme we want to show light colours and for light we want to show dark colours
//        return UpdateViewController.theme == .dark ? .white : .black
//    }
//
//    private var fxBackgroundThemeColour: UIColor {
//        return UpdateViewController.theme == .dark ? .black : .white
//    }
//

    private lazy var closeButton: UIButton = .build { button in
        let closeImage = UIImage(named: ImageIdentifiers.closeLargeButton)
        button.setImage(closeImage, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(self.dismissAnimated), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Update.closeButton
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
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.pageControl
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

        view.backgroundColor = UIColor.theme.browser.background
        setupPageController()
        setupView()
    }

    // MARK: View setup
    private func setupPageController() {
        // Create onboarding card views
        var cardViewController: OnboardingCardViewController

        for (index, cardType) in viewModel.enabledCards.enumerated() {
            let viewModel = viewModel.getCardViewModel(index: index)
            //TODO: Yoana remove bang
            cardViewController = OnboardingCardViewController(viewModel: viewModel!,
                                                                  delegate: self)
            informationCards.append(cardViewController)
        }

        if let firstViewController = informationCards.first {
            pageController.setViewControllers([firstViewController],
                                              direction: .forward,
                                              animated: true,
                                              completion: nil)
        }
    }

    private func setupView() {
        addChild(pageController)
        view.addSubview(pageController.view)
        pageController.didMove(toParent: self)
        view.addSubviews(pageControl, closeButton)

        NSLayoutConstraint.activate([
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                constant: -UX.pageControlBottomPadding),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.closeButtonPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
        ])
    }

    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissedUpdateCoverSheet)
    }

    @objc private func startBrowsing() {
        viewModel.startBrowsing?()
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .dismissUpdateCoverSheetAndStartBrowsing)
    }
}

// MARK: UIPageViewControllerDataSource & UIPageViewControllerDelegate
extension UpdateViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        return nil
//        guard let onboardingVC = viewController as? OnboardingCardViewController,
//              let index = getCardIndex(viewController: onboardingVC) else {
//              return nil
//        }
//
//        pageControl.currentPage = index
//        return getNextOnboardingCard(index: index, goForward: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        return nil
//        guard let onboardingVC = viewController as? OnboardingCardViewController,
//              let index = getCardIndex(viewController: onboardingVC) else {
//              return nil
//        }
//
//        pageControl.currentPage = index
//        return getNextOnboardingCard(index: index, goForward: true)

    }
}

extension UpdateViewController: OnboardingCardDelegate {
    func showNextPage(_ cardType: IntroViewModel.OnboardingCards) {

    }

    func primaryAction(_ cardType: IntroViewModel.OnboardingCards) {

    }

    func pageChanged(_ cardType: IntroViewModel.OnboardingCards) {

    }
}
