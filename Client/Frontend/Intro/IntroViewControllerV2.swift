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
    private lazy var welcomeCardV2: IntroScreenWelcomeViewV2 = {
        let welcomeCardView = IntroScreenWelcomeViewV2()
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()
    private lazy var welcomeCardV1: IntroScreenWelcomeViewV1 = {
        let welcomeCardView = IntroScreenWelcomeViewV1()
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()
    private lazy var syncCardV2: IntroScreenSyncViewV2 = {
        let syncCardView = IntroScreenSyncViewV2()
        syncCardView.clipsToBounds = true
        return syncCardView
    }()
    private lazy var syncCardV1: IntroScreenSyncViewV1 = {
        let syncCardView = IntroScreenSyncViewV1()
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
        // Initialize
        view.addSubview(syncCardV1)
        view.addSubview(welcomeCardV1)
        // Constraints
        setupWelcomeCardV1()
        setupSyncCardV1()
    }
    
    private func setupWelcomeCardV1() {
        // Constraints
        welcomeCardV1.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Buton action closures
        // Next button action
        welcomeCardV1.nextClosure = {
            UIView.animate(withDuration: 0.3, animations: {
                self.welcomeCardV1.alpha = 0
            }) { _ in
                self.welcomeCardV1.isHidden = true
            }
        }
        // Close button action
        welcomeCardV1.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
        // Sign in button closure
        welcomeCardV1.signInClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
        // Sign up button closure
        welcomeCardV1.signUpClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
    
    private func setupSyncCardV1() {
        syncCardV1.snp.makeConstraints() { make in
            make.edges.equalToSuperview()
        }
        
        // Close button closure
        syncCardV1.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
        // Sign in button closure
        syncCardV1.signInClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
        // Sign up button closure
        syncCardV1.signUpClosure = {
            self.didFinishClosure?(self, .emailLoginFlow)
        }
    }
    
    // V2 of onboarding intro view
    private func setupIntroViewV2() {
        // Initialize
        view.addSubview(syncCardV2)
        view.addSubview(welcomeCardV1)
        // Constraints
        setupWelcomeCardV1()
        setupSyncCardV2()
    }
    
    private func setupWelcomeCardV2() {
        // Constraints
        welcomeCardV2.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Buton action closures
        // Next button action
        welcomeCardV2.nextClosure = {
            UIView.animate(withDuration: 0.3, animations: {
                self.welcomeCardV2.alpha = 0
            }) { _ in
                self.welcomeCardV2.isHidden = true
            }
        }
        // Close button action
        welcomeCardV2.closeClosure = {
            self.didFinishClosure?(self, nil)
        }
    }
    
    private func setupSyncCardV2() {
        syncCardV2.snp.makeConstraints() { make in
            make.edges.equalToSuperview()
        }
        // Start browsing button action
        syncCardV2.startBrowsing = {
            self.didFinishClosure?(self, nil)
        }
        // Sign-up browsing button action
        syncCardV2.signUp = {
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
