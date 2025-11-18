// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common

protocol TabTrayAnimationDelegate: AnyObject {
    @MainActor
    func applyTheme(fromIndex: Int, toIndex: Int, progress: CGFloat)
}

@MainActor
class TabTrayThemeAnimator {
    struct UX {
        static let animationDuration: CFTimeInterval = 0.25
    }

    weak var delegate: TabTrayAnimationDelegate?

    private var animationDisplayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    private var themeFromIndex = 0
    private var themeToIndex = 0

    var isAnimating: Bool {
        return animationDisplayLink != nil
    }

    func animateThemeTransition(fromIndex: Int, toIndex: Int) {
        animationDisplayLink?.invalidate()

        themeFromIndex = fromIndex
        themeToIndex = toIndex
        animationStartTime = CACurrentMediaTime()

        animationDisplayLink = CADisplayLink(target: self, selector: #selector(handleThemeAnimationTick))
        animationDisplayLink?.add(to: .main, forMode: .common)
    }

    @objc
    nonisolated private func handleThemeAnimationTick() {
        ensureMainThread {
            let elapsed = CACurrentMediaTime() - self.animationStartTime
            let progress = min(max(elapsed / UX.animationDuration, 0), 1)

            self.delegate?.applyTheme(
                fromIndex: self.themeFromIndex,
                toIndex: self.themeToIndex,
                progress: CGFloat(progress)
            )

            if progress >= 1 {
                self.animationDisplayLink?.invalidate()
                self.animationDisplayLink = nil
            }
        }
    }
}
