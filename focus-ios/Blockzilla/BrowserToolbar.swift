/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

class BrowserToolbar: UIView {
    private let toolset = BrowserToolset()
    private let backgroundDark = GradientBackgroundView()
    private let backgroundBright = GradientBackgroundView(alpha: 0.2)
    private let stackView = UIStackView()

    init() {
        super.init(frame: CGRect.zero)

        let background = UIView()
        background.alpha = 0.9
        background.backgroundColor = UIConstants.colors.background
        addSubview(background)

        background.addSubview(backgroundDark)

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        background.addSubview(backgroundBright)

        let borderView = UIView()
        borderView.backgroundColor = UIConstants.Photon.Grey70
        addSubview(borderView)

        stackView.distribution = .fillEqually

        stackView.addArrangedSubview(toolset.backButton)
        stackView.addArrangedSubview(toolset.forwardButton)
        stackView.addArrangedSubview(toolset.stopReloadButton)
        stackView.addArrangedSubview(toolset.sendButton)
        addSubview(stackView)

        borderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(1)
        }

        stackView.snp.makeConstraints { make in
            make.top.right.left.equalTo(self)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }

        background.snp.makeConstraints { make in
            make.top.equalTo(borderView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self)
        }

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(background)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(background)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var delegate: BrowserToolsetDelegate? {
        didSet {
            toolset.delegate = delegate
        }
    }

    var canGoBack: Bool = false {
        didSet {
            toolset.canGoBack = canGoBack
        }
    }

    var canGoForward: Bool = false {
        didSet {
            toolset.canGoForward = canGoForward
        }
    }

    var isLoading: Bool = false {
        didSet {
            toolset.isLoading = isLoading

            let duration = UIConstants.layout.urlBarTransitionAnimationDuration
            backgroundDark.animateHidden(!isLoading, duration: duration)
            backgroundBright.animateHidden(isLoading, duration: duration)
        }
    }
}
