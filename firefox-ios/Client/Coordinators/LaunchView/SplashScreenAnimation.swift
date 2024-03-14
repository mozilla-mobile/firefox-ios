// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Lottie
import UIKit
import SwiftUI

// Animation for when the user launches the app on first run
struct SplashScreenAnimation {
    private let animationView: LottieAnimationView
    private enum UX {
        static let imageSize = 130
    }

    init() {
        animationView = LottieAnimationView(name: "splashScreen.json")
    }

    func configureAnimation(with view: UIView) {
        setupAnimation(with: view)
        playAnimation(with: view)
    }

    private func setupAnimation(with view: UIView) {
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundColor = .systemBackground

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalToConstant: CGFloat(UX.imageSize)),
            animationView.widthAnchor.constraint(equalToConstant: CGFloat(UX.imageSize)),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func playAnimation(with view: UIView) {
        animationView.play { _ in
            animationView.removeFromSuperview()
        }
    }
}
