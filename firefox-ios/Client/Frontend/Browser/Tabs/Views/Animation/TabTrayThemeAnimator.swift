// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol TabTrayAnimationDelegate: AnyObject {
    func applyTheme(fromIndex: Int, toIndex: Int, progress: CGFloat)
}

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
    private func handleThemeAnimationTick() {
        let elapsed = CACurrentMediaTime() - animationStartTime
        let progress = min(max(elapsed / UX.animationDuration, 0), 1)

        delegate?.applyTheme(fromIndex: themeFromIndex, toIndex: themeToIndex, progress: CGFloat(progress))

        if progress >= 1 {
            animationDisplayLink?.invalidate()
            animationDisplayLink = nil
        }
    }
}
