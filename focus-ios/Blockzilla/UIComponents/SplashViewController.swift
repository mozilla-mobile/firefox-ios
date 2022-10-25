// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit
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

    private let logoImage = UIImageView(image: AppInfo.config.wordmark)

    private lazy var authButton: UIButton = {
        let button = UIButton(type: .system)
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
        logoImage.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }

        view.addSubview(authButton)
        authButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImage).inset(100)
            make.height.width.equalTo(CGFloat.authButtonSize)
        }

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
    static let authButtonSize = 44
}

fileprivate extension CATransform3D {
    static let start = CATransform3DMakeScale(0.8, 0.8, 1.0)
    static let mid = CATransform3DMakeScale(2.0, 2.0, 1.0)
}
