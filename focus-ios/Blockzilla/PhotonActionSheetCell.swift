/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct PhotonActionSheetCellUX {
    static let LabelColor = UIColor.blue
    static let BorderWidth: CGFloat = CGFloat(0.5)
    static let CellSideOffset = 20
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let StatusIconSize = 24
    static let SelectedOverlayColor = UIColor(rgb: 0x5D5F79)
    static let CornerRadius: CGFloat = 3
}

class PhotonActionSheetCell: UITableViewCell {
    static let Padding: CGFloat = 16
    static let HorizontalPadding: CGFloat = 10
    static let VerticalPadding: CGFloat = 2
    static let IconSize = 16
    var actionSheet: PhotonActionSheet?
    
    static let reuseIdentifier = "PhotonActionSheetCell"
    
    private func createLabel() -> UILabel {
        let label = UILabel()
        label.minimumScaleFactor = 0.75 // Scale the font if we run out of space
        label.textColor = PhotonActionSheetCellUX.LabelColor
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.adjustsFontSizeToFitWidth = true
        return label
    }
    
    private func createIconImageView() -> UIImageView {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        return icon
    }
    
    lazy var titleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 4
        label.font = .body16
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = .body16
        return label
    }()
    
    lazy var statusIcon: UIImageView = {
        return createIconImageView()
    }()
    
    lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var disclosureIndicator: UIImageView = {
        let disclosureIndicator = createIconImageView()
        disclosureIndicator.image = UIImage(named: "menu-Disclosure")
        return disclosureIndicator
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = PhotonActionSheetCell.Padding
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()
    
    override func prepareForReuse() {
        self.statusIcon.image = nil
        disclosureIndicator.removeFromSuperview()
        disclosureLabel.removeFromSuperview()
        statusIcon.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        isAccessibilityElement = true
        backgroundColor = .clear
        
        // Setup our StackViews
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.spacing = PhotonActionSheetCell.VerticalPadding
        textStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStackView.alignment = .leading
        textStackView.axis = .vertical
        
        stackView.addArrangedSubview(textStackView)
        stackView.addArrangedSubview(statusIcon)
        contentView.addSubview(stackView)
        
        let padding = PhotonActionSheetCell.Padding
        let shrinkage: CGFloat = UIScreen.main.isSmallScreen ? 3 : 0
        let topPadding = PhotonActionSheetCell.HorizontalPadding - shrinkage
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(contentView).inset(UIEdgeInsets(top: topPadding, left: padding, bottom: topPadding, right: padding))
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with action: PhotonActionSheetItem) {
        titleLabel.text = action.title
        titleLabel.textColor = .primaryText
        titleLabel.textColor = action.accessory == .Text ? titleLabel.textColor.withAlphaComponent(0.6) : titleLabel.textColor
        titleLabel.numberOfLines = 0
        
        subtitleLabel.text = action.text
        subtitleLabel.textColor = .secondaryText
        subtitleLabel.isHidden = action.text == nil
        titleLabel.font = action.bold ? .body16Bold : .body16
        accessibilityIdentifier = action.iconString
        accessibilityLabel = action.title
        selectionStyle = .none
        
        if let iconName = action.iconString, let image = UIImage(named: iconName) {
            statusIcon.image = image.createScaled(size: PhotonActionSheetUX.IconSize)
            if statusIcon.superview == nil {
                if action.iconAlignment == .right {
                    stackView.addArrangedSubview(statusIcon)
                } else {
                    stackView.insertArrangedSubview(statusIcon, at: 0)
                }
            } else {
                if action.iconAlignment == .right {
                    statusIcon.removeFromSuperview()
                    stackView.addArrangedSubview(statusIcon)
                }
            }
        } else {
            statusIcon.removeFromSuperview()
        }
        
        if action.textStyle == .subtitle {
            subtitleLabel.textColor = .tertiaryLabel
            subtitleLabel.font = .footnote12
        }
        
        switch action.accessory {
        case .Text:
            disclosureLabel.font = action.bold ? .body16Bold : .body16
            disclosureLabel.text = action.accessoryText
            disclosureLabel.textColor = titleLabel.textColor
            disclosureLabel.accessibilityIdentifier = "\(action.title).Subtitle"
            stackView.addArrangedSubview(disclosureLabel)
        case .Switch:
            let toggle = UISwitch()
            toggle.isOn = action.isEnabled
            toggle.onTintColor = .magenta40
            toggle.tintColor = .grey10.withAlphaComponent(0.2)
            toggle.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
            toggle.accessibilityIdentifier = "\(action.title).Toggle"
            stackView.addArrangedSubview(toggle)
        default:
            break
        }
    }
    @objc func valueChanged(sender: UISwitch) {
        actionSheet?.didToggle(enabled: sender.isOn)
    }
}
