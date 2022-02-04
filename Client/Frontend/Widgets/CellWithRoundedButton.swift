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
    // Tableview cell items
    
//    override var indentationLevel: Int {
//        didSet {
//            containerView.snp.remakeConstraints { make in
//                make.height.equalTo(44)
//                make.top.bottom.equalToSuperview()
//                make.leading.equalToSuperview().offset(indentationLevel * Int(indentationWidth))
//                make.trailing.equalTo(accessoryView?.snp.leading ?? contentView.snp.trailing)
//            }
//        }
//    }
    
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
        button.backgroundColor = .Photon.LightGrey40
        button.setTitleColor(.black, for: .normal)
        button.setTitle(.TabsTray.InactiveTabs.CloseAllInactiveTabsButton, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.clear.cgColor
        button.accessibilityIdentifier = "roundedButton"
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let containerView = UIView()
//    let midView = UIView()
    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular
    func initialViewSetup() {
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.selectionStyle = .default
//        midView.addSubview(roundedButton)
//        containerView.addSubview(roundedButton)

        contentView.addSubview(roundedButton)
//        bringSubviewToFront(containerView)
        
        
        roundedButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        
        roundedButton.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalTo(contentView.snp.trailing).offset(-18)
//            make.top.equalTo(contentView.snp.top).offset(7)
//            make.bottom.equalTo(contentView.snp.bottom).offset(-7)
            make.leading.equalTo(contentView.snp.leading).offset(18)
        }
        
//        containerView.snp.makeConstraints { make in
//            make.height.equalTo(44)
//            make.top.bottom.equalToSuperview()
//            make.leading.equalToSuperview()
//            make.trailing.equalToSuperview()
//        }

//        midView.snp.makeConstraints { make in
//            make.height.equalTo(42)
//            make.centerY.equalToSuperview()
//            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
//        }
        
        selectedBackgroundView = selectedView
        applyTheme()
    }
    
    func updateMidConstraint() {
//        containerView.snp.remakeConstraints { make in
//            make.height.equalTo(44)
//            make.top.bottom.equalToSuperview()
//            make.leading.equalToSuperview()
//            make.trailing.equalToSuperview()
//        }
        
//        midView.snp.remakeConstraints { make in
//            make.height.equalTo(42)
//            make.centerY.equalToSuperview()
//            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
//        }
    }
    
    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        selectedView.backgroundColor = UIColor.theme.tableView.selectedBackground
        if theme == .dark {
            self.backgroundColor = .clear
//            self.titleLabel.textColor = .white
        } else {
            self.backgroundColor = .clear
//            self.titleLabel.textColor = .black
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)
        applyTheme()
    }
}
