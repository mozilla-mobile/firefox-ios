// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Combine

class SplashViewController: UIViewController {
    init(authenticationManager: AuthenticationManager) {
        self.authenticationManager = authenticationManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }

    enum State {
        case needsAuth
        case `default`
    }

    var state = State.default {
        didSet {
            self.updateUI()
        }
    }

    var authenticationManager: AuthenticationManager

    private lazy var logoImage: UIImageView = {
        let logoImage = UIImageView(image: AppInfo.config.wordmark)
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        return logoImage
    }()

    private lazy var authButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .systemBackground
        button.setTitle(UIConstants.strings.unlockWithBiometricsActionButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.addBackgroundView(color: .authButtonBackground, cornerRadius: .cornerRadius)
        button.addTarget(self, action: #selector(self.showAuth), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var cancellable: AnyCancellable?

    private func commonInit() {
        view.backgroundColor = .launchScreenBackground
        view.addSubview(authButton)
        view.addSubview(logoImage)

        logoImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImage.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            authButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.topAnchor.constraint(equalTo: logoImage.topAnchor, constant: .authButtonTop),
            authButton.heightAnchor.constraint(equalToConstant: .authButtonHeight),
            authButton.widthAnchor.constraint(equalToConstant: .authButtonWidth),
            authButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: .authButtonInset),
            authButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -.authButtonInset)
        ])

        updateUI()

        cancellable = authenticationManager
            .$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .loggedin:
                    break

                case .loggedout:
                    self.state = .default

                case .canceled:
                    self.state = .needsAuth
                }
            }
    }

    private func updateUI() {
        authButton.isHidden = state == .default
    }

    @objc
    private func showAuth() {
        state = .default
        Task {
            await authenticationManager.authenticateWithBiometrics()
        }
    }
}

fileprivate extension UIColor {
    static let authButtonBackground = UIColor.actionButton
}

fileprivate extension CGFloat {
    static let cornerRadius: CGFloat = 12
    static let authButtonHeight: CGFloat = 44
    static let authButtonWidth: CGFloat = 500
    static let authButtonTop: CGFloat = 80
    static let authButtonInset: CGFloat = 16
}

fileprivate extension CATransform3D {
    static let start = CATransform3DMakeScale(0.8, 0.8, 1.0)
    static let mid = CATransform3DMakeScale(2.0, 2.0, 1.0)
}
