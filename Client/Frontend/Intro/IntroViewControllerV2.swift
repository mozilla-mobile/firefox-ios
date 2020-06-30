/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import Leanplum

class IntroViewControllerV2: UIViewController {
    // Public constants
    let viewModel:IntroViewModelV2 = IntroViewModelV2()
    // private var
    private var onboardingType: OnboardingScreenType?
    // Private views
    private lazy var welcomeCard: IntroScreenWelcomeViewV2 = {
        let welcomeCardView = IntroScreenWelcomeViewV2()
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()
    private lazy var syncCard: IntroScreenSyncViewV2 = {
        let syncCardView = IntroScreenSyncViewV2()
        syncCardView.clipsToBounds = true
        return syncCardView
    }()
    private lazy var introWelcomeSyncV1Views: IntroWelcomeAndSyncViewV1 = {
        let syncCardView = IntroWelcomeAndSyncViewV1()
        syncCardView.clipsToBounds = true
        return syncCardView
    }()
    // Closure delegate
    var didFinishClosure: ((IntroViewControllerV2, FxAPageType?) -> Void)?
    
    // MARK: Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    

    convenience init(onboardingType: OnboardingScreenType?) {
        self.init()
        self.onboardingType = onboardingType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }
    
    // MARK: View setup
    private func initialViewSetup() {
        let screenType = onboardingType == nil ? viewModel.screenType : onboardingType
        switch screenType {
        case .versionV1:
            setupIntroViewV1()
        case .versionV2:
            setupIntroViewV2()
        case .none:
            setupIntroViewV1()
        }
    }
    
    // V1 of onboarding intro view
    func setupIntroViewV1() {
        view.addSubview(introWelcomeSyncV1Views)
        // Constraints
        introWelcomeSyncV1Views.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Close button closure
        introWelcomeSyncV1Views.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
        // Sign in button closure
        introWelcomeSyncV1Views.signInClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
        // Sign up button closure
        introWelcomeSyncV1Views.signUpClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
    
    // V2 of onboarding intro view
    private func setupIntroViewV2() {
        // Initialize
        view.addSubview(syncCard)
        view.addSubview(welcomeCard)
        // Constraints
        setupWelcomeCard()
        setupSyncCard()
    }
    
    private func setupWelcomeCard() {
        // Constraints
        welcomeCard.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Buton action closures
        // Next button action
        welcomeCard.nextClosure = {
            UIView.animate(withDuration: 0.3, animations: {
                self.welcomeCard.alpha = 0
            }) { _ in
                self.welcomeCard.isHidden = true
            }
        }
        // Close button action
        welcomeCard.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
    }
    
    private func setupSyncCard() {
        syncCard.snp.makeConstraints() { make in
            make.edges.equalToSuperview()
        }
        // Start browsing button action
        syncCard.startBrowsing = {
            self.didFinishClosure?(self, nil)
        }
        // Sign-up browsing button action
        syncCard.signUp = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
}

// MARK: UIViewController setup
extension IntroViewControllerV2 {
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
