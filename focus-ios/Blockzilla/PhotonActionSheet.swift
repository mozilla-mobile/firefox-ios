/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 
 Ported with modifications from Firefox iOS (https://github.com/mozilla-mobile/firefox-ios)
 
 */

import Foundation
import SnapKit

private func isSmallScreen() -> Bool {
    let size = UIScreen.main.bounds.size
    return min(size.width, size.height) < 700
}

private struct PhotonActionSheetUX {
    static let MaxWidth: CGFloat = 414
    static let Padding: CGFloat = 10
    static let HeaderFooterHeight: CGFloat = 0
    static let RowHeight: CGFloat = 50
    static let BorderWidth: CGFloat = 0.5
    static let BorderColor = UIConstants.Photon.Grey30
    static let CornerRadius: CGFloat = 10
    static let SiteImageViewSize = 52
    static let IconSize = CGSize(width: 24, height: 24)
    static let SiteHeaderName  = "PhotonActionSheetSiteHeaderView"
    static let TitleHeaderName = "PhotonActionSheetTitleHeaderView"
    static let CellName = "PhotonActionSheetCell"
    static let CloseButtonHeight: CGFloat  = 56
    static let TablePadding: CGFloat = 6
    static let BackgroundAlpha: CGFloat = 0.9
    static let TitleHeaderHeight: CGFloat = 36
    static let SeparatorHeaderHeight: CGFloat = 12
    static let SeparatorColor = UIConstants.Photon.Grey10.withAlphaComponent(0.2)
    static let TableViewBackgroundColor = UIConstants.Photon.Ink90.withAlphaComponent(PhotonActionSheetUX.BackgroundAlpha)
    static let BlurAlpha: CGFloat = 0.7
}

public struct PhotonActionSheetItem {
    public enum IconAlignment {
        case left
        case right
    }
    
    public fileprivate(set) var title: String
    public fileprivate(set) var text: String?
    public fileprivate(set) var iconString: String?
    public fileprivate(set) var iconURL: URL?
    public fileprivate(set) var iconAlignment: IconAlignment
    
    public var isEnabled: Bool
    public fileprivate(set) var accessory: PhotonActionSheetCellAccessoryType
    public fileprivate(set) var accessoryText: String?
    public fileprivate(set) var bold: Bool = false
    public fileprivate(set) var handler: ((PhotonActionSheetItem) -> Void)?
    
    init(title: String, text: String? = nil, iconString: String? = nil, iconAlignment: IconAlignment = .left, isEnabled: Bool = false, accessory: PhotonActionSheetCellAccessoryType = .None, accessoryText: String? = nil, bold: Bool? = false, handler: ((PhotonActionSheetItem) -> Void)? = nil) {
        self.title = title
        self.iconString = iconString
        self.iconAlignment = iconAlignment
        self.isEnabled = isEnabled
        self.accessory = accessory
        self.handler = handler
        self.text = text
        self.accessoryText = accessoryText
        self.bold = bold ?? false
    }
}

protocol PhotonActionSheetDelegate: class {
    func photonActionSheetDidDismiss()
    func photonActionSheetDidToggleProtection(enabled: Bool)
}

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    weak var delegate: PhotonActionSheetDelegate?
    fileprivate(set) var actions: [[PhotonActionSheetItem]]
    
    private var tintColor = UIConstants.Photon.Grey10
    private var heightConstraint: Constraint?
    var tableView = UITableView(frame: .zero, style: .grouped)
    var darkenedBackgroundView = UIView()
    
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(dismiss))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setTitle(UIConstants.strings.close, for: .normal)
        button.backgroundColor = UIConstants.Photon.Ink70
        button.setTitleColor(UIConstants.Photon.Grey10, for: .normal)
        button.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        button.titleLabel?.font = UIConstants.fonts.closeButtonTitle
        button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        button.accessibilityIdentifier = "PhotonMenu.close"
        return button
    }()
    
    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = photonTransitionDelegate
        }
    }
    
    init(title: String? = nil, actions: [[PhotonActionSheetItem]], closeButtonTitle: String = UIConstants.strings.close, style presentationStyle: UIModalPresentationStyle) {
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.closeButton.setTitle(closeButtonTitle, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"
        
        // In a popover the popover provides the blur background
        // Not using a background color allows the view to style correctly with the popover arrow
        if self.popoverPresentationController == nil {
            tableView.backgroundColor = PhotonActionSheetUX.TableViewBackgroundColor
            let blurEffect = UIBlurEffect(style: .regular)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.alpha = PhotonActionSheetUX.BlurAlpha
            tableView.backgroundView = blurEffectView
        } else {
            tableView.backgroundColor = .clear
        }
        
        let width = min(self.view.frame.size.width, PhotonActionSheetUX.MaxWidth) - (PhotonActionSheetUX.Padding * 2)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                make.width.equalTo(width)
                make.height.equalTo(PhotonActionSheetUX.CloseButtonHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(PhotonActionSheetUX.Padding)
            }
        }
        
        tableView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view.snp.centerX)
            if UIDevice.current.userInterfaceIdiom == .phone {
                make.bottom.equalTo(closeButton.snp.top).offset(-PhotonActionSheetUX.Padding)
            } else {
                make.edges.equalTo(self.view)
            }
            make.width.equalTo(width)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: "SeparatorSectionHeader")
        tableView.register(PhotonActionSheetTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.TitleHeaderName)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "EmptyHeader")
        tableView.estimatedRowHeight = PhotonActionSheetUX.RowHeight
        tableView.estimatedSectionFooterHeight = PhotonActionSheetUX.HeaderFooterHeight
        tableView.estimatedSectionHeaderHeight = PhotonActionSheetUX.HeaderFooterHeight
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"
        let origin = CGPoint(x: 0, y: 0)
        let size = CGSize(width: tableView.frame.width, height: PhotonActionSheetUX.Padding)
        let footer = UIView(frame: CGRect(origin: origin, size: size))
        tableView.tableHeaderView = footer
        tableView.tableFooterView = footer.clone()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let maxHeight = self.view.frame.height - PhotonActionSheetUX.CloseButtonHeight
        tableView.snp.makeConstraints { make in
            heightConstraint?.deactivate()
            // The height of the menu should be no more than 85 percent of the screen
            heightConstraint = make.height.equalTo(min(self.tableView.contentSize.height, maxHeight * 0.90)).constraint
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.preferredContentSize = self.tableView.contentSize
        }
    }
    
    private func applyBackgroundBlur() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let screenshot = appDelegate.window?.screenshot() {
            let imageView = UIImageView(image: screenshot)
            view.addSubview(imageView)
        }
    }
    
    @objc func dismiss(_ gestureRecognizer: UIGestureRecognizer? = nil) {
        delegate?.photonActionSheetDidDismiss()
        self.dismiss(animated: true, completion: nil)
    }

    func dismissWithCallback(callback: @escaping () -> ()) {
        delegate?.photonActionSheetDidDismiss()
        self.dismiss(animated: true) { callback() }
    }
    
    @objc func didToggle(enabled: Bool) {
        delegate?.photonActionSheetDidToggleProtection(enabled: enabled)
        dismiss()
        delegate?.photonActionSheetDidDismiss()
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if tableView.frame.contains(touch.location(in: self.view)) {
            return false
        }
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions[section].count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)
        var action = actions[indexPath.section][indexPath.row]
        guard let handler = action.handler else {
            self.dismiss()
            return
        }
        
        if action.accessory == .Switch {
            action.isEnabled = !action.isEnabled
            actions[indexPath.section][indexPath.row] = action
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadData()
            delegate?.photonActionSheetDidToggleProtection(enabled: action.isEnabled)
            handler(action)
        } else {
            self.dismissWithCallback {
                handler(action)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.section][indexPath.row]
        cell.tintColor = self.tintColor
        cell.accessibilityIdentifier = action.title
        if action.accessory == .Switch {
            cell.actionSheet = self
        }
        cell.configure(with: action)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = PhotonActionSheetCellUX.SelectedOverlayColor
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // If we have multiple sections show a separator for each one except the first.
        if section > 0 {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
        }
        
        if let title = title {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.TitleHeaderName) as! PhotonActionSheetTitleHeaderView
            header.tintColor = self.tintColor
            header.configure(with: title)
            return header
        }
        
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        return view
    }
    
    // A height of at least 1 is required to make sure the default header size isnt used when laying out with AutoLayout
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    // A height of at least 1 is required to make sure the default footer size isnt used when laying out with AutoLayout
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            if title != nil {
                return PhotonActionSheetUX.TitleHeaderHeight
            } else {
                return 1
            }
        default:
            return PhotonActionSheetUX.SeparatorHeaderHeight
        }
    }
}

private class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView {
    static let Padding: CGFloat = 12
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIConstants.fonts.actionMenuTitle
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIConstants.Photon.Grey10.withAlphaComponent(0.6)
        return titleLabel
    }()
    
    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = PhotonActionSheetUX.SeparatorColor
        return separatorLine
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(PhotonActionSheetTitleHeaderView.Padding)
            make.trailing.greaterThanOrEqualTo(contentView)
            make.top.equalTo(contentView).offset(PhotonActionSheetUX.TablePadding)
        }
        
        contentView.addSubview(separatorView)
        
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(PhotonActionSheetUX.TablePadding)
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with title: String) {
        self.titleLabel.text = title
    }
    
    override func prepareForReuse() {
        self.titleLabel.text = nil
    }
}

private struct PhotonActionSheetCellUX {
    static let LabelColor = UIColor.blue
    static let BorderWidth: CGFloat = CGFloat(0.5)
    static let CellSideOffset = 20
    static let TitleLabelOffset = 10
    static let CellTopBottomOffset = 12
    static let StatusIconSize = 24
    static let SelectedOverlayColor = UIColor(rgb: 0x5D5F79)
    static let CornerRadius: CGFloat = 3
}

private class PhotonActionSheetSeparator: UITableViewHeaderFooterView {
    
    let separatorLineView = UIView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()
        separatorLineView.backgroundColor = PhotonActionSheetUX.SeparatorColor
        self.contentView.addSubview(separatorLineView)
        separatorLineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.centerY.equalTo(self)
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum PhotonActionSheetCellAccessoryType {
    case Switch
    case Text
    case None
}

private class PhotonActionSheetCell: UITableViewCell {
    static let Padding: CGFloat = 16
    static let HorizontalPadding: CGFloat = 10
    static let VerticalPadding: CGFloat = 2
    static let IconSize = 16
    var actionSheet: PhotonActionSheet?
    
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
        label.font = UIConstants.fonts.actionMenuItem
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = UIConstants.fonts.actionMenuItem
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
        
        stackView.addArrangedSubview(statusIcon)
        stackView.addArrangedSubview(textStackView)
        contentView.addSubview(stackView)
        
        let padding = PhotonActionSheetCell.Padding
        let shrinkage: CGFloat = isSmallScreen() ? 3 : 0
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
        titleLabel.textColor = self.tintColor
        titleLabel.textColor = action.accessory == .Text ? titleLabel.textColor.withAlphaComponent(0.6) : titleLabel.textColor
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        
        subtitleLabel.text = action.text
        subtitleLabel.textColor = self.tintColor
        subtitleLabel.isHidden = action.text == nil
        titleLabel.font  = action.bold ? UIConstants.fonts.actionMenuItemBold : UIConstants.fonts.actionMenuItem
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
        
        switch action.accessory {
        case .Text:
            disclosureLabel.font  = action.bold ? UIConstants.fonts.actionMenuItemBold : UIConstants.fonts.actionMenuItem
            disclosureLabel.text = action.accessoryText
            disclosureLabel.textColor = titleLabel.textColor
            disclosureLabel.accessibilityIdentifier = "\(action.title).Subtitle"
            stackView.addArrangedSubview(disclosureLabel)
        case .Switch:
            let toggle = UISwitch()
            toggle.isOn = action.isEnabled
            toggle.onTintColor = UIConstants.colors.toggleOn
            toggle.tintColor = UIConstants.colors.toggleOff
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
