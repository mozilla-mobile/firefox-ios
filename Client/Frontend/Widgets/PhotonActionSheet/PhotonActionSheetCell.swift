// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import SnapKit
import Shared

// MARK: PhotonActionSheetCellUX
private struct PhotonActionSheetCellUX {
    static let LabelColor = UIConstants.SystemBlueColor
    static let BorderWidth = CGFloat(0.5)
    static let CellSideOffset = 20
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let StatusIconSize = 24
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
    static let Padding: CGFloat = 16
    static let HorizontalPadding: CGFloat = 1
    static let topBottomPadding: CGFloat = 10
    static let VerticalPadding: CGFloat = 2
    static let IconSize = 16
}

// This file is the cells used for the PhotonActionSheet table view.
class PhotonActionSheetCell: UITableViewCell {

    // MARK: - Variables

    private var badgeOverlay: BadgeWithBackdrop?

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.minimumScaleFactor = 0.75 // Scale the font if we run out of space
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

    private lazy var titleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 4
        label.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        return label
    }()

    private lazy var statusIcon: UIImageView = {
        return createIconImageView()
    }()

    private lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private let toggleSwitch = ToggleSwitch()

    private lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = PhotonActionSheetCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()

    private lazy var disclosureIndicator: UIImageView = {
        let disclosureIndicator = createIconImageView()
        disclosureIndicator.image = UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate)
        disclosureIndicator.tintColor = UIColor.theme.tableView.accessoryViewTint
        return disclosureIndicator
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = PhotonActionSheetCellUX.Padding
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    let bottomBorder = UIView()

    // MARK: - init

    override func prepareForReuse() {
        super.prepareForReuse()
        self.statusIcon.image = nil
        disclosureIndicator.removeFromSuperview()
        disclosureLabel.removeFromSuperview()
        toggleSwitch.mainView.removeFromSuperview()
        statusIcon.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
        badgeOverlay?.backdrop.removeFromSuperview()
        badgeOverlay?.badge.removeFromSuperview()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        isAccessibilityElement = true
        contentView.addSubview(selectedOverlay)
        backgroundColor = .clear

        // Setup our StackViews
        let textStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStackView.spacing = PhotonActionSheetCellUX.VerticalPadding
        textStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStackView.alignment = .leading
        textStackView.axis = .vertical

        stackView.addArrangedSubview(textStackView)
        stackView.addArrangedSubview(statusIcon)
        contentView.addSubview(stackView)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupConstraints() {
        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        stackView.snp.makeConstraints { make in
            let padding = PhotonActionSheetCellUX.Padding
            let topPadding = PhotonActionSheetCellUX.topBottomPadding
            make.edges.equalTo(contentView).inset(UIEdgeInsets(top: topPadding,
                                                               left: padding,
                                                               bottom: topPadding,
                                                               right: padding))
        }

        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(PhotonActionSheetCellUX.StatusIconSize)
        }

        addSubBorder()
    }

    func addSubBorder() {
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
        self.contentView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // Hiding bottom border by default
        bottomBorder.isHidden = true
    }
    
    func configure(with action: PhotonActionSheetItem) {
        titleLabel.text = action.title
        titleLabel.font = action.bold ? DynamicFontHelper.defaultHelper.DeviceFontLargeBold : DynamicFontHelper.defaultHelper.SemiMediumRegularWeightAS
        titleLabel.textColor = UIColor.theme.tableView.rowText
        titleLabel.textColor = action.accessory == .Text ? titleLabel.textColor.withAlphaComponent(0.6) : titleLabel.textColor
        titleLabel.adjustsFontSizeToFitWidth = false
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.minimumScaleFactor = 0.5
        action.customRender?(titleLabel, contentView)

        subtitleLabel.text = action.text
        subtitleLabel.textColor = UIColor.theme.tableView.rowText
        subtitleLabel.isHidden = action.text == nil
        subtitleLabel.numberOfLines = 0

        accessibilityIdentifier = action.iconString ?? action.accessibilityId
        accessibilityLabel = action.title
        selectionStyle = action.tapHandler != nil ? .default : .none

        if let iconName = action.iconString {
            setupActionName(action: action, name: iconName)
        } else {
            statusIcon.removeFromSuperview()
        }

        setupBadgeOverlay(action: action)
        setupAccessory(action: action)
    }

    private func setupActionName(action: PhotonActionSheetItem, name: String) {
        switch action.iconType {
        case .Image:
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.tintColor = action.iconTint ?? self.tintColor

        case .URL:
            let image = UIImage(named: name)?.createScaled(PhotonActionSheetUX.IconSize)
            statusIcon.layer.cornerRadius = PhotonActionSheetUX.IconSize.width / 2
            statusIcon.sd_setImage(with: action.iconURL, placeholderImage: image, options: [.avoidAutoSetImage]) { (img, err, _, _) in
                if let img = img, self.accessibilityLabel == action.title {
                    self.statusIcon.image = img.createScaled(PhotonActionSheetUX.IconSize)
                    self.statusIcon.layer.cornerRadius = PhotonActionSheetUX.IconSize.width / 2
                }
            }

        case .TabsButton:
            let label = UILabel(frame: CGRect())
            label.text = action.tabCount
            label.font = UIFont.boldSystemFont(ofSize: UIConstants.DefaultChromeSmallSize)
            label.textColor = UIColor.theme.textField.textAndTint
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.centerX.equalTo(statusIcon)
                make.centerY.equalTo(statusIcon)
            }

        case .None:
            break
        }

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
    }

    private func setupBadgeOverlay(action: PhotonActionSheetItem) {
        guard let name = action.badgeIconName, action.isEnabled, let parent = statusIcon.superview else { return }
        badgeOverlay = BadgeWithBackdrop(imageName: name)
        badgeOverlay?.add(toParent: parent)
        badgeOverlay?.layout(onButton: statusIcon)
        badgeOverlay?.show(true)

        // Custom dark theme tint needed here, it is overkill to create a '.theme' color just for this.
        let customDarkTheme = UIColor(white: 0.3, alpha: 1)
        let color = LegacyThemeManager.instance.currentName == .dark ? customDarkTheme : UIColor.theme.actionMenu.closeButtonBackground
        badgeOverlay?.badge.tintBackground(color: color)
    }

    private func setupAccessory(action: PhotonActionSheetItem) {
        switch action.accessory {
        case .Text:
            disclosureLabel.font = action.bold ? DynamicFontHelper.defaultHelper.DeviceFontLargeBold : DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
            disclosureLabel.text = action.accessoryText
            disclosureLabel.textColor = titleLabel.textColor
            stackView.addArrangedSubview(disclosureLabel)
        case .Disclosure:
            stackView.addArrangedSubview(disclosureIndicator)
        case .Switch:
            toggleSwitch.setOn(action.isEnabled)
            stackView.addArrangedSubview(toggleSwitch.mainView)
        case .None:
            break // Do nothing. The rest are not supported yet.
        }
    }
}
