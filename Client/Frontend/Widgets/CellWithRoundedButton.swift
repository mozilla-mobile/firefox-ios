// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation


struct CellWithRoundedButtonUX {
    static let ImageSize: CGFloat = 29
    static let ImageCornerRadius: CGFloat = 6
    static let HorizontalMargin: CGFloat = 16
}

class CellWithRoundedButton: UITableViewCell, NotificationThemeable {
    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()
    
    private lazy var roundedButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setImage(UIImage(named: "trash-icon"), for: .normal)
        button.tintColor = .black
        button.backgroundColor = .Photon.LightGrey30
        button.setTitleColor(.black, for: .normal)
        button.setTitle(.TabsTray.InactiveTabs.CloseAllInactiveTabsButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 13.5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityIdentifier = "roundedButton"
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var buttonClosure: (() -> Void)?
    
    let containerView = UIView()
    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular
    func initialViewSetup() {
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.selectionStyle = .default
        
        contentView.addSubview(roundedButton)
        roundedButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        
        roundedButton.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            let trailingOffSet = UIDevice.current.userInterfaceIdiom == .pad ? -100 : -23
            let leadingOffSet = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 23
            make.trailing.equalTo(contentView.snp.trailing).offset(trailingOffSet)
            make.leading.equalTo(contentView.snp.leading).offset(leadingOffSet)
        }

        selectedBackgroundView = selectedView
        applyTheme()
    }
    
    func applyTheme() {
        selectedView.backgroundColor = UIColor.theme.tableView.selectedBackground
        self.backgroundColor = .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)
        applyTheme()
    }
    
    @objc func buttonPressed() {
        self.buttonClosure?()
    }
}
