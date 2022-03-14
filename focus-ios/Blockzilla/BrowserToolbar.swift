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
    public var deleteButton: InsetButton { toolset.deleteButton }

    init() {
        super.init(frame: CGRect.zero)

        let background = UIView()
        background.backgroundColor = .foundation
        addSubview(background)

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
}
