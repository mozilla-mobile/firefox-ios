// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Lottie
import UIKit
import SwiftUI

// Animation for when the user confirms they want to delete their data through the data clearance flow in private mode
// There are different animations depending on the orientation of the device
struct DataClearanceAnimation {
    enum AnimationType {
        case phonePortrait
        case phoneLandscape
        case wave
        case gradient

        var name: String {
            switch self {
            case .phonePortrait:
                return "portrait.json"
            case .phoneLandscape:
                return "landscape.json"
            case .wave:
                return "wave.json"
            case .gradient:
                return "gradient.json"
            }
        }
    }

    private func setup(with fileName: String, contentMode: UIView.ContentMode) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(fileName)
        animationView.animation = animation
        animationView.contentMode = contentMode
        animationView.loopMode = .playOnce
        animationView.play { _ in
            animationView.removeFromSuperview()
        }
        return animationView
    }

    /// Determines which animation type to display depending on device orientation
    /// Check whether device is a phone and if not, we check if top tabs are shown, otherwise we default to phone mode
    /// - Parameter showsTopTabs: true or false if top tabs is shown
    /// - Returns: data clearance animation type
    func startAnimation(with view: UIView, for showTopTabs: Bool) {
        guard UIDevice.current.userInterfaceIdiom != .phone else {
            setupForPhone(with: view)
            return
        }

        if showTopTabs {
            setupForiPad(with: view)
        } else {
            return setupForPhone(with: view)
        }
    }

    /// Creates animation view for iphone layout using either portrait or landscape lottie files
    /// - Parameters:
    ///   - view: parent view that contains the animation
    private func setupForPhone(with view: UIView) {
        let type: AnimationType =  UIDevice.current.isIphoneLandscape ? .phoneLandscape : .phonePortrait
        let animationView = setup(with: type.name, contentMode: .scaleAspectFill)

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews(animationView)

        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// Creates animation view for iPad layout combining gradient and wave lottie files so that
    /// the animation constraints looks good in various orientations
    /// - Parameters:
    ///   - view: parent view that contains the animation
    private func setupForiPad(with view: UIView) {
        let gradientView = setup(with: AnimationType.gradient.name, contentMode: .scaleAspectFill)
        let animationView = setup(with: AnimationType.wave.name, contentMode: .scaleAspectFit)

        animationView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviews(gradientView, animationView)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}
