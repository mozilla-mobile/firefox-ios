/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

class BrowserToolbar: UIView {
    let toolset = BrowserToolset()
    private let backgroundLoading = GradientBackgroundView()
    private let backgroundDark = UIView()
    private let backgroundBright = UIView()
    private let stackView = UIStackView()
    
    public var contextMenuButton: InsetButton { toolset.contextMenuButton }

    init() {
        super.init(frame: CGRect.zero)

        let background = UIView()
        background.backgroundColor = .foundation
        addSubview(background)

        addSubview(backgroundLoading)
        addSubview(backgroundDark)

        backgroundDark.backgroundColor = .foundation
        backgroundBright.backgroundColor = .foundation

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        background.addSubview(backgroundBright)

        stackView.distribution = .fillEqually

        stackView.addArrangedSubview(toolset.backButton)
        stackView.addArrangedSubview(toolset.forwardButton)
        stackView.addArrangedSubview(toolset.deleteButton)
        stackView.addArrangedSubview(toolset.contextMenuButton)
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.right.left.equalTo(self)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }

        background.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(self)
        }

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(background)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(background)
        }

        backgroundLoading.snp.makeConstraints { make in
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
    
    var canDelete: Bool = false {
        didSet {
            toolset.canDelete = canDelete
        }
    }

    enum toolbarState {
        case bright
        case dark
        case loading
    }

    var color: toolbarState = .loading {
        didSet {
            let duration = UIConstants.layout.urlBarTransitionAnimationDuration
            backgroundDark.animateHidden(color != .dark, duration: duration)
            backgroundBright.animateHidden(color != .bright, duration: duration)
            backgroundLoading.animateHidden(currentTheme == .light ? true : color != .loading, duration: duration)
            toolset.isLoading = color == .loading
        }
    }
}
