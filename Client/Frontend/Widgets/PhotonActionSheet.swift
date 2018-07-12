/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit
import Shared

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
    static let BorderColor = UIColor.Photon.Grey30
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
    public fileprivate(set) var iconType: PhotonActionSheetIconType
    public fileprivate(set) var iconAlignment: IconAlignment

    public var isEnabled: Bool // Used by toggles like nightmode to switch tint color
    public fileprivate(set) var accessory: PhotonActionSheetCellAccessoryType
    public fileprivate(set) var accessoryText: String?
    public fileprivate(set) var bold: Bool = false
    public fileprivate(set) var handler: ((PhotonActionSheetItem) -> Void)?
    
    init(title: String, text: String? = nil, iconString: String? = nil, iconURL: URL? = nil, iconType: PhotonActionSheetIconType = .URL, iconAlignment: IconAlignment = .left, isEnabled: Bool = false, accessory: PhotonActionSheetCellAccessoryType = .None, accessoryText: String? = nil, bold: Bool? = false, handler: ((PhotonActionSheetItem) -> Void)? = nil) {
        self.title = title
        self.iconString = iconString
        self.iconURL = iconURL
        self.iconType = iconType
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

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    fileprivate(set) var actions: [[PhotonActionSheetItem]]

    var syncManager: SyncManager? // used to display the sync button
    
    private var site: Site?
    private let style: PresentationStyle
    private var tintColor = UIColor.Photon.Grey80
    private var heightConstraint: Constraint?
    var tableView = UITableView(frame: .zero, style: .grouped)

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
        button.setTitle(Strings.CloseButtonTitle, for: .normal)
        button.backgroundColor = UIConstants.AppBackgroundColor
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontExtraLargeBold
        button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        button.accessibilityIdentifier = "PhotonMenu.close"
        return button
    }()

    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = photonTransitionDelegate
        }
    }
    
    init(site: Site, actions: [PhotonActionSheetItem], closeButtonTitle: String = Strings.CloseButtonTitle) {
        self.site = site
        self.actions = [actions]
        self.style = .centered
        super.init(nibName: nil, bundle: nil)
        self.closeButton.setTitle(closeButtonTitle, for: .normal)
    }

    init(title: String? = nil, actions: [[PhotonActionSheetItem]], closeButtonTitle: String = Strings.CloseButtonTitle, style presentationStyle: UIModalPresentationStyle) {
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
            self.tintColor = UIConstants.SystemBlueColor
        }
        
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"

        // In a popover the popover provides the blur background
        // Not using a background color allows the view to style correctly with the popover arrow
        if self.popoverPresentationController == nil {
            tableView.backgroundColor = UIConstants.AppBackgroundColor.withAlphaComponent(0.7)
            let blurEffect = UIBlurEffect(style: .light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            tableView.backgroundView = blurEffectView
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
                make.bottom.equalTo(self.view.safeArea.bottom).inset(PhotonActionSheetUX.Padding)
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

        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRotateSyncIcon), name: .ProfileDidStartSyncing, object: nil)
    }

    @objc func stopRotateSyncIcon() {
        ensureMainThread {
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetSiteHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.SiteHeaderName)
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
        let footer = UIView(frame: CGRect(width: tableView.frame.width, height: PhotonActionSheetUX.Padding))
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
            let blurredImage = screenshot.applyBlur(withRadius: 5,
                                                    blurType: BOXFILTER,
                                                    tintColor: UIColor.black.withAlphaComponent(0.2),
                                                    saturationDeltaFactor: 1.8,
                                                    maskImage: nil)
            let imageView = UIImageView(image: blurredImage)
            view.addSubview(imageView)
        }
    }
    
    @objc func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        self.dismiss(animated: true, completion: nil)
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
            self.dismiss(nil)
            return
        }
        
        // Switches can be toggled on/off without dismissing the menu
        if action.accessory == .Switch {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action.isEnabled = !action.isEnabled
            actions[indexPath.section][indexPath.row] = action
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadData()
        } else {
            self.dismiss(nil)
        }

        return handler(action)
    }
    
    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.section][indexPath.row]
        cell.tintColor = self.tintColor
        let syncManager = action.accessory == .Sync ? self.syncManager : nil
        cell.configure(with: action, syncManager: syncManager)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // If we have multiple sections show a separator for each one except the first.
        if section > 0 {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
        }

        if let site = site {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.SiteHeaderName) as! PhotonActionSheetSiteHeaderView
            header.tintColor = self.tintColor
            header.configure(with: site)
            return header
        } else if let title = title {
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
        titleLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        titleLabel.numberOfLines = 1
        titleLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor.Photon.Grey50
        return titleLabel
    }()

    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = UIColor.Photon.Grey40
        return separatorLine
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
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

private class PhotonActionSheetSiteHeaderView: UITableViewHeaderFooterView {
    static let Padding: CGFloat = 12
    static let VerticalPadding: CGFloat = 2

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeBoldFontAS
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        return titleLabel
    }()
    
    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeRegularWeightAS
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = .center
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        siteImageView.layer.borderColor = PhotonActionSheetUX.BorderColor.cgColor
        siteImageView.layer.borderWidth = PhotonActionSheetUX.BorderWidth
        return siteImageView
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(siteImageView)
        
        siteImageView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(PhotonActionSheetSiteHeaderView.Padding)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(PhotonActionSheetSiteHeaderView.Padding)
            make.size.equalTo(PhotonActionSheetUX.SiteImageViewSize)
        }
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.spacing = PhotonActionSheetSiteHeaderView.VerticalPadding
        stackView.alignment = .leading
        stackView.axis = .vertical
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(PhotonActionSheetSiteHeaderView.Padding)
            make.trailing.equalTo(contentView).inset(PhotonActionSheetSiteHeaderView.Padding)
            make.centerY.equalTo(siteImageView.snp.centerY)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        self.siteImageView.image = nil
        self.siteImageView.backgroundColor = UIColor.clear
    }
    
    func configure(with site: Site) {
        self.siteImageView.setFavicon(forSite: site) { (color, url) in
            self.siteImageView.backgroundColor = color
            self.siteImageView.image = self.siteImageView.image?.createScaled(PhotonActionSheetUX.IconSize)
        }
        self.titleLabel.text = site.title.isEmpty ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain
    }
}

private struct PhotonActionSheetCellUX {
    static let LabelColor = UIConstants.SystemBlueColor
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
        separatorLineView.backgroundColor = UIColor.Photon.Grey40
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
    case Disclosure
    case Switch
    case Text
    case Sync // Sync is a special case.
    case None
}

public enum PhotonActionSheetIconType {
    case Image
    case URL
    case TabsButton
    case None
}

private class PhotonActionSheetCell: UITableViewCell {
    static let Padding: CGFloat = 16
    static let HorizontalPadding: CGFloat = 10
    static let VerticalPadding: CGFloat = 2
    static let IconSize = 16

    var syncButton: SyncMenuButton?
    var tabButton: TabsButton?

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
        label.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = createLabel()
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        return label
    }()
    
    lazy var statusIcon: UIImageView = {
        return createIconImageView()
    }()

    lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    lazy var toggleSwitch: UIImageView = {
        let toggle = UIImageView(image: UIImage(named: "menu-Toggle-Off"))
        toggle.contentMode = .scaleAspectFit
        return toggle
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
        toggleSwitch.removeFromSuperview()
        statusIcon.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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

    func configure(with action: PhotonActionSheetItem, syncManager: SyncManager? = nil) {
        titleLabel.text = action.title
        titleLabel.textColor = self.tintColor
        titleLabel.textColor = action.accessory == .Text ? titleLabel.textColor.withAlphaComponent(0.6) : titleLabel.textColor
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5

        subtitleLabel.text = action.text
        subtitleLabel.textColor = self.tintColor
        subtitleLabel.isHidden = action.text == nil
        titleLabel.font  = action.bold ? DynamicFontHelper.defaultHelper.DeviceFontLargeBold : DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        accessibilityIdentifier = action.iconString
        accessibilityLabel = action.title
        selectionStyle = action.handler != nil ? .default : .none

        if let iconName = action.iconString {
            switch action.iconType {
            case .Image:
                let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
                statusIcon.image = image
                self.statusIcon.layer.cornerRadius = PhotonActionSheetUX.IconSize.width / 2
                statusIcon.tintColor = self.tintColor
            case .URL:
                let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
                statusIcon.sd_setImage(with: action.iconURL, placeholderImage: image, options: []) { (img, err, _, _) in
                    if let img = img {
                        self.statusIcon.image = img.createScaled(PhotonActionSheetUX.IconSize)
                        self.statusIcon.layer.cornerRadius = PhotonActionSheetUX.IconSize.width / 2
                    }
                }
            case .TabsButton:
                if tabButton == nil {
                    tabButton = TabsButton()
                }
                tabButton?.setTitle("8", for: .normal)
                self.statusIcon.addSubview(tabButton!)
                stackView.addArrangedSubview(tabButton!)
                tabButton?.contentHorizontalAlignment = .left
//                tabButton?.snp.makeConstraints { make in
//                    make.size.equalTo(20)
//                }
                let padding = PhotonActionSheetCell.Padding
                stackView.snp.remakeConstraints { make in
                    make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding))
                }
            default:
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
        } else {
            statusIcon.removeFromSuperview()
        }
        if action.accessory != .Sync {
            syncButton?.removeFromSuperview()
        }

        switch action.accessory {
        case .Text:
            disclosureLabel.font = action.bold ? DynamicFontHelper.defaultHelper.DeviceFontLargeBold : DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
            disclosureLabel.text = action.accessoryText
            disclosureLabel.textColor = titleLabel.textColor
            stackView.addArrangedSubview(disclosureLabel)
        case .Disclosure:
            stackView.addArrangedSubview(disclosureIndicator)
        case .Switch:
            let image = action.isEnabled ? UIImage(named: "menu-Toggle-On") : UIImage(named: "menu-Toggle-Off")
            toggleSwitch.isAccessibilityElement = true
            toggleSwitch.accessibilityIdentifier = action.isEnabled ? "enabled" : "disabled"
            toggleSwitch.image = image
            stackView.addArrangedSubview(toggleSwitch)
        case .Sync:
            if let manager = syncManager {
                if syncButton == nil {
                    let button = SyncMenuButton(with: manager)
                    stackView.addArrangedSubview(button)
                    syncButton = button
                    syncButton?.contentHorizontalAlignment = .right
                    syncButton?.snp.makeConstraints { make in
                        make.size.equalTo(40)
                    }
                }
                syncButton?.updateAnimations()
                let padding = PhotonActionSheetCell.Padding
                stackView.snp.remakeConstraints { make in
                    make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding))
                }
            }
        default:
            break // Do nothing. The rest are not supported yet.
        }
    }
}

private class SyncMenuButton: UIButton {

    let syncManager: SyncManager
    let iconSize = CGSize(width: 24, height: 24)

    init(with syncManager: SyncManager) {
        self.syncManager = syncManager
        super.init(frame: .zero)

        self.addTarget(self, action: #selector(startSync), for: .touchUpInside)

        let line = UIView()
        line.backgroundColor = UIColor.Photon.Grey40
        self.addSubview(line)
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        guard let syncStatus = syncManager.syncDisplayState else {
            self.setImage(UIImage(named: "FxA-Sync")?.createScaled(iconSize), for: .normal)
            return
        }

        let imageName = (syncStatus == .inProgress) ? "FxA-Sync-Blue" : "FxA-Sync"
        setImage(UIImage(named: imageName)?.createScaled(iconSize), for: .normal)

        if syncStatus == .inProgress {
            animate()
        }
    }

    private func animate() {
        let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(Double.pi)
        continuousRotateAnimation.isRemovedOnCompletion = true
        continuousRotateAnimation.duration = 0.5
        continuousRotateAnimation.repeatCount = .infinity
        self.imageView?.layer.add(continuousRotateAnimation, forKey: "rotateKey")
    }

    func updateAnimations() {
        self.imageView?.layer.removeAllAnimations()
        setImage(UIImage(named: "FxA-Sync")?.createScaled(iconSize), for: .normal)
        if let syncStatus = syncManager.syncDisplayState, syncStatus == .inProgress {
            setImage(UIImage(named: "FxA-Sync-Blue")?.createScaled(iconSize), for: .normal)
            animate()
        }
    }

    @objc func startSync() {
        self.syncManager.syncEverything(why: .syncNow)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

