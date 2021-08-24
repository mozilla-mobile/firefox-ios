/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

class IntroViewController: UIViewController, OnViewDismissable {
    var onViewDismissed: (() -> Void)? = nil
    // private var
    // Private views
    private lazy var welcomeCard: IntroScreenWelcomeView = {
        let welcomeCardView = IntroScreenWelcomeView()
        welcomeCardView.clipsToBounds = true
        return welcomeCardView
    }()
    private lazy var syncCard: IntroScreenSyncView = {
        let syncCardView = IntroScreenSyncView()
        syncCardView.clipsToBounds = true
        return syncCardView
    }()
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
    
    //onboarding intro view
    private func setupIntroView() {
        // Initialize
        view.addSubview(syncCard)
        view.addSubview(welcomeCard)
        // Constraints
        setupWelcomeCard()
        setupSyncCard()
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
