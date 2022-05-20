// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

class IntroViewController: UIViewController, OnViewDismissable {
    var onViewDismissed: (() -> Void)?
    let viewModel = IntroViewModel()

//    private var fxBackgroundThemeColor: UIColor {
//        return theme == .dark ? UIColor.Firefox.DarkGrey10 : .white
//    }

    // private var
    // Private views
    private lazy var welcomeCard: IntroScreenWelcomeView = {
        let welcomeCardView = IntroScreenWelcomeView()
        welcomeCardView.translatesAutoresizingMaskIntoConstraints = false
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()

    private lazy var syncCard: IntroScreenSyncView = {
        let syncCardView = IntroScreenSyncView()
        syncCardView.translatesAutoresizingMaskIntoConstraints = false
        syncCardView.clipsToBounds = true
        return syncCardView
    }()

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

    private lazy var onboardingCard: OnboardingCardView = {
        let viewModel = OnboardingCardViewModel()
        let cardView = OnboardingCardView(viewModel: viewModel)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()

    private lazy var pageControl: UIPageControl = .build { pageControl in
        pageControl.currentPage = 0
        pageControl.numberOfPages = 3
    }

    // Closure delegate
    var didFinishClosure: ((IntroViewController, FxAPageType?) -> Void)?

    // MARK: Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard !viewModel.shouldShowNewOnboarding else {
            view.backgroundColor = .lightGray
            setupOnboarding()
            return
        }

        initialViewSetup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }

    // MARK: View setup
    private func initialViewSetup() {
        setupIntroView()
    }

    // onboarding intro view
    private func setupIntroView() {
        // Initialize
        view.addSubview(syncCard)
        view.addSubview(welcomeCard)

        // Constraints
        setupWelcomeCard()
        setupSyncCard()
    }

    private func setupWelcomeCard() {
        NSLayoutConstraint.activate([
            welcomeCard.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomeCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            welcomeCard.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Buton action closures
        // Next button action
        welcomeCard.nextClosure = {
            UIView.animate(withDuration: 0.3, animations: {
                self.welcomeCard.alpha = 0
            }) { _ in
                self.welcomeCard.isHidden = true
                TelemetryWrapper.recordEvent(category: .action, method: .view, object: .syncScreenView)
            }
        }
        // Close button action
        welcomeCard.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
        // Sign in button closure
        welcomeCard.signInClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
        // Sign up button closure
        welcomeCard.signUpClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }

    private func setupSyncCard() {
        NSLayoutConstraint.activate([
            syncCard.topAnchor.constraint(equalTo: view.topAnchor),
            syncCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            syncCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            syncCard.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        // Start browsing button action
        syncCard.startBrowsing = {
            self.didFinishClosure?(self, nil)
        }
        // Sign-up browsing button action
        syncCard.signUp = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }

    // MARK: - Nimbus onboarding
    private func setupOnboarding() {
        view.addSubviews(onboardingCard)
        view.addSubviews(pageControl)

        var constraints = [
            onboardingCard.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 40).priority(UILayoutPriority.defaultLow),
            onboardingCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            onboardingCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            onboardingCard.bottomAnchor.constraint(greaterThanOrEqualTo: pageControl.topAnchor, constant: -40).priority(UILayoutPriority.defaultLow),
            onboardingCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        if viewModel.shouldShowNewOnboarding {
            view.addSubview(closeButton)

            let closeButtonConstraints = [
                closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
                closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                closeButton.widthAnchor.constraint(equalToConstant: 44),
                closeButton.heightAnchor.constraint(equalToConstant: 44)
            ]
            constraints.append(contentsOf: closeButtonConstraints)

        }
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func closeOnboarding() {
        print("Closing onboarding")
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
