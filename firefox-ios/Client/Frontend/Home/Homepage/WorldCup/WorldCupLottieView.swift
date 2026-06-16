// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Lottie
import UIKit

final class WorldCupLottieView: UIView {
    struct Configuration {
        let animationName: String
        let loopMode: LottieLoopMode

        @MainActor
        static let confetti = Configuration(
            animationName: "worldCupConfetti.json",
            loopMode: .repeat(2)
        )

        @MainActor
        static let kit = Configuration(
            animationName: "worldCupKit.json",
            loopMode: .playOnce
        )
    }

    private struct UX {
        static let fadeOutDuration: TimeInterval = 0.3
        static let kitHeight: CGFloat = 200
    }

    private let configuration: Configuration
    private let animationView: LottieAnimationView

    // MARK: - Play

    @MainActor
    static func showConfetti(
        in container: UIView,
        reduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    ) {
        guard !reduceMotionEnabled else { return }

        let view = WorldCupLottieView(configuration: .confetti)
        container.addSubview(view)
        view.pinToSuperview()
        view.startAnimation()
    }

    @MainActor
    static func showKit(
        in container: UIView,
        reduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    ) {
        guard !reduceMotionEnabled else { return }

        let view = WorldCupLottieView(configuration: .kit)
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: UX.kitHeight)
        ])
        view.startAnimation()
    }

    // MARK: - Init

    init(configuration: Configuration) {
        self.configuration = configuration
        animationView = LottieAnimationView(name: configuration.animationName)
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        backgroundColor = .clear
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = configuration.loopMode
        animationView.isUserInteractionEnabled = false
        addSubview(animationView)
        animationView.pinToSuperview()
    }

    // MARK: - Animation

    private func startAnimation() {
        // if the animation failed to load, don't leave a dangling
        // overlay on the container.
        guard animationView.animation != nil else {
            removeFromSuperview()
            return
        }
        animationView.play { [weak self] _ in
            UIView.animate(
                withDuration: UX.fadeOutDuration,
                animations: { self?.alpha = 0 },
                completion: { _ in self?.removeFromSuperview() }
            )
        }
    }
}
