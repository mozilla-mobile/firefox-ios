// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

// MARK: PhotonActionSheetViewUX
struct PhotonActionSheetViewUX {
    static let LabelColor = UIConstants.SystemBlueColor
    static let BorderWidth = CGFloat(0.5)
    static let CellSideOffset = 20
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let StatusIconSize = CGSize(width: 24, height: 24)
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
    static let Padding: CGFloat = 16
    static let HorizontalPadding: CGFloat = 1
    static let topBottomPadding: CGFloat = 10
    static let VerticalPadding: CGFloat = 2
    static let IconSize = 16
}

// This is the view contained in PhotonActionSheetContainerCell in the PhotonActionSheet table view.
// More than one PhotonActionSheetView can be in the parent container cell.
class PhotonActionSheetView: UIView {

    // MARK: - Variables

    private var badgeOverlay: BadgeWithBackdrop?

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.minimumScaleFactor = 0.75 // Scale the font if we run out of space
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func createIconImageView() -> UIImageView {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = PhotonActionSheetViewUX.CornerRadius
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
        return icon
    }

    private lazy var titleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        return label
    }()

    private lazy var statusIcon: UIImageView = .build { icon in
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = PhotonActionSheetViewUX.CornerRadius
        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private let toggleSwitch = ToggleSwitch()

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.backgroundColor = PhotonActionSheetViewUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
    }

    private lazy var disclosureIndicator: UIImageView = {
        let disclosureIndicator = createIconImageView()
        disclosureIndicator.image = UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate)
        disclosureIndicator.tintColor = UIColor.theme.tableView.accessoryViewTint
        return disclosureIndicator
    }()

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.spacing = PhotonActionSheetViewUX.Padding
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
    }

    private lazy var textStackView: UIStackView = .build { textStackView in
        textStackView.spacing = PhotonActionSheetViewUX.VerticalPadding
        textStackView.setContentHuggingPriority(.required, for: .horizontal)
        textStackView.alignment = .leading
        textStackView.axis = .vertical
        textStackView.distribution = .fillProportionally
    }

    // TODO: Laurie - Gesture listener ??
//    override var isSelected: Bool {
//        didSet {
//            selectedOverlay.isHidden = !isSelected
//        }
//    }

    lazy var bottomBorder: UIView = .build { _ in }
    lazy var verticalBorder: UIView = .build { _ in }

    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func configure(with action: SingleSheetItem) {
        setupViews()

        titleLabel.text = action.title
        titleLabel.font = action.bold ? DynamicFontHelper.defaultHelper.DeviceFontLargeBold : DynamicFontHelper.defaultHelper.SemiMediumRegularWeightAS
        titleLabel.textColor = UIColor.theme.tableView.rowText
        titleLabel.textColor = action.accessory == .Text ? titleLabel.textColor.withAlphaComponent(0.6) : titleLabel.textColor
        action.customRender?(titleLabel, self)

        subtitleLabel.text = action.text
        subtitleLabel.textColor = UIColor.theme.tableView.rowText
        subtitleLabel.isHidden = action.text == nil

        accessibilityIdentifier = action.iconString ?? action.accessibilityId
        accessibilityLabel = action.title
        // TODO: laurie - selection
//        selectionStyle = action.tapHandler != nil ? .default : .none

        if action.isFlipped {
            transform = CGAffineTransform(scaleX: 1, y: -1)
        }

        if let iconName = action.iconString {
            setupActionName(action: action, name: iconName)
        } else {
            statusIcon.removeFromSuperview()
        }

        setupBadgeOverlay(action: action)
        setupAccessory(action: action)
        addSubBorder(action: action)
    }

    func addVerticalBorder(shouldAdd: Bool) {
        verticalBorder.backgroundColor = UIColor.theme.tableView.separator
        addSubview(verticalBorder)

        NSLayoutConstraint.activate([
            verticalBorder.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            verticalBorder.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 1),
            verticalBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalBorder.widthAnchor.constraint(equalToConstant: 1)
        ])
    }

    private func setupViews() {
        isAccessibilityElement = true
        addSubview(selectedOverlay)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        // Setup our StackViews
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(textStackView)
        stackView.addArrangedSubview(statusIcon)
        addSubview(stackView)

        setupConstraints()
    }

    private func setupConstraints() {
        let padding = PhotonActionSheetViewUX.Padding
        let topBottomPadding = PhotonActionSheetViewUX.topBottomPadding

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: topBottomPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -topBottomPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),

            selectedOverlay.topAnchor.constraint(equalTo: topAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),

            statusIcon.widthAnchor.constraint(equalToConstant: PhotonActionSheetViewUX.StatusIconSize.width),
            statusIcon.heightAnchor.constraint(equalToConstant: PhotonActionSheetViewUX.StatusIconSize.height),
        ])
    }

    private func addSubBorder(action: SingleSheetItem) {
        bottomBorder.backgroundColor = UIColor.theme.tableView.separator
        addSubview(bottomBorder)

        var constraints = [NSLayoutConstraint]()
        // Determine if border should be at top or bottom when flipping
        let top = bottomBorder.topAnchor.constraint(equalTo: topAnchor, constant: 1)
        let bottom = bottomBorder.bottomAnchor.constraint(equalTo: bottomAnchor)
        let anchor = action.isFlipped ? top : bottom

        let borderConstraints = [
            anchor,
            bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1)
        ]
        constraints.append(contentsOf: borderConstraints)

        NSLayoutConstraint.activate(constraints)
    }

    private func setupActionName(action: SingleSheetItem, name: String) {
        switch action.iconType {
        case .Image:
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.tintColor = action.iconTint ?? action.tintColor ?? self.tintColor

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
            label.translatesAutoresizingMaskIntoConstraints = false
            let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.addSubview(label)
            statusIcon.tintColor = action.tintColor ?? self.tintColor

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: statusIcon.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: statusIcon.centerYAnchor),
            ])

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

    private func setupBadgeOverlay(action: SingleSheetItem) {
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

    private func setupAccessory(action: SingleSheetItem) {
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
