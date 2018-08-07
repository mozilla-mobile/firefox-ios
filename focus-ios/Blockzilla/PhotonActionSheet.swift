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
    static let HeaderFooterHeight: CGFloat = 20
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

private enum PresentationStyle {
    case centered // used in the home panels
    case bottom // used to display the menu on phone sized devices
    case popover // when displayed on the iPad
}

protocol PhotonActionSheetDelegate: class {
    func photonActionSheetDidDismiss()
    func photonActionSheetDidToggleProtection(enabled: Bool)
}

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    weak var delegate: PhotonActionSheetDelegate?
    fileprivate(set) var actions: [[PhotonActionSheetItem]]
    
    private let style: PresentationStyle
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
    
    init(actions: [PhotonActionSheetItem], closeButtonTitle: String = UIConstants.strings.close) {
        self.actions = [actions]
        self.style = .centered
        super.init(nibName: nil, bundle: nil)
        self.closeButton.setTitle(closeButtonTitle, for: .normal)
    }
    
    init(title: String? = nil, actions: [[PhotonActionSheetItem]], closeButtonTitle: String = UIConstants.strings.close, style presentationStyle: UIModalPresentationStyle) {
        self.actions = actions
        self.style = presentationStyle == .popover ? .popover : .bottom
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.closeButton.setTitle(closeButtonTitle, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if style == .centered {
            applyBackgroundBlur()
            self.tintColor = UIColor.blue
        }
        
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"
        
        // In a popover the popover provides the blur background
        // Not using a background color allows the view to style correctly with the popover arrow
        if self.popoverPresentationController == nil {
            tableView.backgroundColor = UIConstants.Photon.Ink70
        } else {
            tableView.backgroundColor = .clear
        }
        
        let width = min(self.view.frame.size.width, PhotonActionSheetUX.MaxWidth) - (PhotonActionSheetUX.Padding * 2)
        
        if style == .bottom {
            self.view.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                make.width.equalTo(width)
                make.height.equalTo(PhotonActionSheetUX.CloseButtonHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(PhotonActionSheetUX.Padding)
            }
        }
        
        if style == .popover {
            self.actions = actions.map({ $0.reversed() }).reversed()
            tableView.snp.makeConstraints { make in
                make.edges.equalTo(self.view)
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                switch style {
                case .bottom, .popover:
                    make.bottom.equalTo(closeButton.snp.top).offset(-PhotonActionSheetUX.Padding)
                case .centered:
                    make.centerY.equalTo(self.view.snp.centerY)
                }
                make.width.equalTo(width)
            }
        }
        tableView.alpha = 0.9
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.TitleHeaderName)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: "SeparatorSectionHeader")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "EmptyHeader")
        tableView.estimatedRowHeight = PhotonActionSheetUX.RowHeight
        tableView.estimatedSectionFooterHeight = PhotonActionSheetUX.HeaderFooterHeight
        // When the menu style is centered the header is much bigger than default. Set a larger estimated height to make sure autolayout sizes the view correctly
        tableView.estimatedSectionHeaderHeight = (style == .centered) ? PhotonActionSheetUX.RowHeight : PhotonActionSheetUX.HeaderFooterHeight
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
        let maxHeight = self.view.frame.height - (style == .bottom ? PhotonActionSheetUX.CloseButtonHeight : 0)
        tableView.snp.makeConstraints { make in
            heightConstraint?.deactivate()
            // The height of the menu should be no more than 85 percent of the screen
            heightConstraint = make.height.equalTo(min(self.tableView.contentSize.height, maxHeight * 0.90)).constraint
        }
        if style == .popover {
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
        if action.accessory == .Switch {
            cell.actionSheet = self
        }
        cell.configure(with: action)
        return cell
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
        
        // A header height of at least 1 is required to make sure the default header size isnt used when laying out with AutoLayout
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        view?.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        return view
    }
    
    // A footer height of at least 1 is required to make sure the default footer size isnt used when laying out with AutoLayout
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        view?.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        return view
    }
}

private class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView {
    static let Padding: CGFloat = 12
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIConstants.fonts.actionMenuItem
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIColor.black
        return titleLabel
    }()
    
    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIConstants.Photon.Grey40
        return separatorLine
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = UIColor.black
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(PhotonActionSheetTitleHeaderView.Padding)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView).offset(PhotonActionSheetUX.TablePadding)
        }
        
        contentView.addSubview(separatorView)
        
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(PhotonActionSheetUX.TablePadding)
            make.bottom.equalTo(contentView).inset(PhotonActionSheetUX.TablePadding)
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
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let CornerRadius: CGFloat = 3
}

private class PhotonActionSheetSeparator: UITableViewHeaderFooterView {
    
    let separatorLineView = UIView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        separatorLineView.backgroundColor = UIColor.black
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
    
    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = PhotonActionSheetCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
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
    
    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        self.statusIcon.image = nil
        disclosureIndicator.removeFromSuperview()
        disclosureLabel.removeFromSuperview()
        statusIcon.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        isAccessibilityElement = true
        contentView.addSubview(selectedOverlay)
        backgroundColor = .clear
        
        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
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
        selectionStyle = action.handler != nil ? .default : .none
        
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
            stackView.addArrangedSubview(disclosureLabel)
        case .Switch:
            let toggle = UISwitch()
            toggle.isOn = action.isEnabled
            toggle.onTintColor = UIConstants.colors.toggleOn
            toggle.tintColor = UIConstants.colors.toggleOff
            toggle.addTarget(self, action: #selector(valueChanged(sender:)), for: .valueChanged)
            stackView.addArrangedSubview(toggle)
        default:
            break
        }
    }
    @objc func valueChanged(sender: UISwitch) {
        actionSheet?.didToggle(enabled: sender.isOn)
    }
}
