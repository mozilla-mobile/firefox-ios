// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import DesignSystem
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .black
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addBackgroundView(color: .authButtonBackground, cornerRadius: .cornerRadius, padding: .padding)
        button.addTarget(self, action:#selector(self.showAuth), for: .touchUpInside)
        return button
    }()

    var cancellable: AnyCancellable?

    private func commonInit() {
        authButton.setImage(
            authenticationManager.biometricType == .faceID ? .faceid : .touchid,
            for: .normal
        )
        view.backgroundColor = .launchScreenBackground
        view.addSubview(logoImage)
        view.addSubview(authButton)

        NSLayoutConstraint.activate([
            logoImage.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.topAnchor.constraint(equalTo: logoImage.topAnchor, constant: CGFloat.authButtonTopInset),
            authButton.widthAnchor.constraint(equalToConstant: CGFloat.authButtonSize),
            authButton.heightAnchor.constraint(equalToConstant: CGFloat.authButtonSize)
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

    @objc private func showAuth() {
        state = .default
        Task {
            await authenticationManager.authenticateWithBiometrics()
        }
    }
}

fileprivate extension UIColor {
    static let authButtonBackground = UIColor.white.withAlphaComponent(0.5)
}

fileprivate extension CGFloat {
    static let cornerRadius: CGFloat = 22
    static let padding: CGFloat = 8
    static let authButtonSize: CGFloat = 44
    static let authButtonTopInset: CGFloat = 100
}

fileprivate extension CATransform3D {
    static let start = CATransform3DMakeScale(0.8, 0.8, 1.0)
    static let mid = CATransform3DMakeScale(2.0, 2.0, 1.0)
}
