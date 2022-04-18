/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import DesignSystem

class SplashView: UIView {

    enum State {
        case needsAuth
        case `default`
    }

    var state = State.default {
        didSet {
            self.updateUI()
        }
    }

    var authenticationManager: AuthenticationManager! {
        didSet {
            authButton.setImage(
                authenticationManager.biometricType == .faceID ? .faceid : .touchid,
                for: .normal
            )
        }
    }

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .launchScreenBackground
        addSubview(logoImage)
        logoImage.snp.makeConstraints { make in
            make.center.equalTo(self)
        }

        addSubview(authButton)
        authButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImage).inset(100)
            make.height.width.equalTo(CGFloat.authButtonSize)
        }

        updateUI()
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

    func animateDissapear(_ duration: Double = 0.25) {
        UIView.animate(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.logoImage.layer.transform = .start
        }, completion: { success in
            UIView.animate(withDuration: duration, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                self.alpha = 0
                self.logoImage.layer.transform = .mid
            }, completion: { success in
                self.isHidden = true
                self.logoImage.layer.transform = CATransform3DIdentity
            })
        })
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
