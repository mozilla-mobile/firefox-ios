/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ActionFooterView: UIView {

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIConstants.fonts.tableSectionHeader //.systemFont(ofSize: 13)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var detailTextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.accent, for: .normal)
        button.setTitleColor(.accent, for: .highlighted)
        button.titleLabel?.font = UIConstants.fonts.tableSectionHeader
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [textLabel, detailTextButton])
        stackView.spacing = 0
        stackView.alignment = .leading
        stackView.axis = .vertical
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
