/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import Leanplum

class IntroViewControllerV2: UIViewController {
    private lazy var welcomeCard: IntroScreenWelcomeView = {
        let welcomeCardView = IntroScreenWelcomeView()
        welcomeCardView.contentMode = .scaleAspectFit
        welcomeCardView.clipsToBounds = true
        welcomeCardView.tag = 0
        return welcomeCardView
    }()
    private lazy var syncCard: IntroScreenSyncView = {
        let syncCardView = IntroScreenSyncView()
        syncCardView.contentMode = .scaleAspectFit
        syncCardView.clipsToBounds = true
        syncCardView.tag = 0
        return syncCardView
    }()
    // Closure delegate
    var didFinishClosure: ((IntroViewControllerV2,FxAPageType?) -> Void)?
    
    // MARK: Initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }
    
    // MARK: View setup
    private func initialViewSetup() {
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
            print("Going to next screen")
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
            self.didFinishClosure?(self, .signUpFlow)
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
