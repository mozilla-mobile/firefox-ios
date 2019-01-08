/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class URLBarContainer: UIView {
    private let backgroundEditing = GradientBackgroundView(background: UIConstants.colors.background)
    private let backgroundDark = UIView()
    private let backgroundBright = GradientBackgroundView(alpha: 0.8, background: UIConstants.colors.background)

    init() {
        super.init(frame: CGRect.zero)

        addSubview(backgroundEditing)

        backgroundDark.backgroundColor = UIConstants.colors.background
        backgroundDark.isHidden = true
        backgroundDark.alpha = 0
        addSubview(backgroundDark)

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        addSubview(backgroundBright)

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        backgroundEditing.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    enum BarState {
        case bright
        case dark
        case editing
    }

    var barState: BarState = .editing {
        didSet {
            guard barState != oldValue else { return }

            let newBackgroundView = view(for: barState)
            let oldBackgroundView = view(for: oldValue)
            let newBackgroundViewZIndex = subviews.firstIndex(of: newBackgroundView) ?? -1
            let oldBackgroundViewZIndex = subviews.firstIndex(of: oldBackgroundView) ?? -1

            if newBackgroundViewZIndex > oldBackgroundViewZIndex {
                // If the background view to show is above the last shown view, wait to hide the previous view until the
                // animation completes to prevent content below the url bar from displaying
                newBackgroundView.animateHidden(false, duration: UIConstants.layout.urlBarTransitionAnimationDuration) {
                    oldBackgroundView.animateHidden(true, duration: 0)
                }
            } else {
                // If the background view to show is below the last updated, display it immediatly so content below the url
                // bar is not displayed during the transition
                newBackgroundView.animateHidden(false, duration: 0)
                oldBackgroundView.animateHidden(true, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func view(for barState: BarState) -> UIView {
        switch barState {
        case .bright:
            return backgroundBright
        case .dark:
            return backgroundDark
        case .editing:
            return backgroundEditing
        }
    }
}
