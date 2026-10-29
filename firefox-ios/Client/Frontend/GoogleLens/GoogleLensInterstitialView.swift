// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class GoogleLensInterstitialView: UIView, ThemeApplicable {
    private enum UX {
        static let entranceDuration: TimeInterval = 0.4
        static let exitDuration: TimeInterval = 0.3
    }

    private let materialBackdrop: UIVisualEffectView = .build()
    private let opaqueBackdrop: UIView = .build { view in
        view.alpha = 0
    }
    private var animator: UIViewPropertyAnimator?
    private var isBackdropVisible = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        accessibilityViewIsModal = true
        addSubview(materialBackdrop)
        materialBackdrop.pinToSuperview()
        addSubview(opaqueBackdrop)
        opaqueBackdrop.pinToSuperview()
    }

    func animateEntrance() {
        isBackdropVisible = true
        let animator = UIViewPropertyAnimator(duration: UX.entranceDuration, curve: .easeOut) { [weak self] in
            self?.materialBackdrop.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            self?.opaqueBackdrop.alpha = 1
        }
        self.animator = animator
        animator.startAnimation()
    }

    func animateExit(completion: @escaping () -> Void) {
        if let animator, animator.state == .active {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current)
        }
        isBackdropVisible = false
        let animator = UIViewPropertyAnimator(duration: UX.exitDuration, curve: .easeInOut) { [weak self] in
            self?.materialBackdrop.effect = nil
            self?.opaqueBackdrop.alpha = 0
        }
        animator.addCompletion { [weak self] _ in
            self?.animator = nil
            completion()
        }
        self.animator = animator
        animator.startAnimation()
    }

    func stopAnimation() {
        if let animator, animator.state == .active {
            animator.stopAnimation(true)
        }
        animator = nil
    }

    func applyTheme(theme: Theme) {
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        materialBackdrop.isHidden = reduceTransparency
        opaqueBackdrop.isHidden = !reduceTransparency
        opaqueBackdrop.backgroundColor = theme.colors.layerScrim.withAlphaComponent(1)
        if animator?.state != .active {
            materialBackdrop.effect = isBackdropVisible ? UIBlurEffect(style: .systemUltraThinMaterialDark) : nil
            opaqueBackdrop.alpha = isBackdropVisible ? 1 : 0
        }
    }
}
