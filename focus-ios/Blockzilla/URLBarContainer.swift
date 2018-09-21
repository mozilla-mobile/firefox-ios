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

    enum barState {
        case bright
        case dark
        case editing
    }
    
    var color: barState = .editing {
        didSet {
            backgroundDark.animateHidden(color != .dark, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            backgroundBright.animateHidden(color != .bright, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            backgroundEditing.animateHidden(color != .editing, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
