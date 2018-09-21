/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class HomeViewToolbar: UIView {
    let toolset = BrowserToolset()
    private let stackView = UIStackView()
    
    init() {
        super.init(frame: CGRect.zero)
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(toolset.backButton)
        stackView.addArrangedSubview(toolset.forwardButton)
        toolset.stopReloadButton.isEnabled = false
        stackView.addArrangedSubview(toolset.stopReloadButton)
        stackView.addArrangedSubview(toolset.settingsButton)
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.right.left.equalTo(self)
            make.height.equalTo(UIConstants.layout.browserToolbarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide)
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
}
