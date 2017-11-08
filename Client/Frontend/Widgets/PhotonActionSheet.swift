/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit
import Shared

private struct PhotonActionSheetUX {
    static let MaxWidth: CGFloat = 414
    static let Padding: CGFloat = 10
    static let SectionVerticalPadding: CGFloat = 13
    static let HeaderHeight: CGFloat = 80
    static let RowHeight: CGFloat = 44
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor(rgb: 0x353535)
    static let DescriptionLabelColor = UIColor(rgb: 0x919191)
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let BorderWidth: CGFloat = 0.5
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
    static let CornerRadius: CGFloat = 10
    static let SiteImageViewSize = 52
    static let IconSize = CGSize(width: 24, height: 24)
    static let HeaderName  = "PhotonActionSheetHeaderView"
    static let CellName = "PhotonActionSheetCell"
    static let CancelButtonHeight: CGFloat  = 56
    static let TablePadding: CGFloat = 6
}

public struct PhotonActionSheetItem {
    public fileprivate(set) var title: String
    public fileprivate(set) var iconString: String
    public fileprivate(set) var isEnabled: Bool // Used by toggles like nightmode to switch tint color
    public fileprivate(set) var handler: ((PhotonActionSheetItem) -> Void)?
    
    init(title: String, iconString: String, isEnabled: Bool = false, handler: ((PhotonActionSheetItem) -> Void)?) {
        self.title = title
        self.iconString = iconString
        self.isEnabled = isEnabled
        self.handler = handler
    }
}

private enum PresentationStyle {
    case centered // used in the home panels
    case bottom // used to display the menu
}

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    fileprivate(set) var actions: [[PhotonActionSheetItem]]
    
    private var site: Site?
    private let style: PresentationStyle
    private lazy var showCancelButton: Bool = {
        return self.style == .bottom && self.modalPresentationStyle != .popover
    }()
    var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    private var tintColor = UIColor(rgb: 0x272727)
    private var outerScrollView = UIScrollView()
    
    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(PhotonActionSheet.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.CancelButtonTitle, for: .normal)
        button.backgroundColor = UIConstants.AppBackgroundColor
        button.setTitleColor(UIConstants.SystemBlueColor, for: .normal)
        button.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontExtraLargeBold
        button.addTarget(self, action: #selector(PhotonActionSheet.dismiss(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = "PhotonMenu.cancel"
        return button
    }()
    
    init(site: Site, actions: [PhotonActionSheetItem]) {
        self.site = site
        self.actions = [actions]
        self.style = .centered
        super.init(nibName: nil, bundle: nil)
    }
    
    init(actions: [[PhotonActionSheetItem]]) {
        self.actions = actions
        self.style = .bottom
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = photonTransitionDelegate
        }
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
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionFooterHeight = 0
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.HeaderName)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: "SeparatorSectionHeader")
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = PhotonActionSheetUX.CornerRadius
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"
        let footer = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: tableView.frame.width, height: PhotonActionSheetUX.TablePadding)))
        tableView.tableFooterView = footer
        tableView.tableHeaderView = footer.clone()

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
        let height = actionSheetHeight()
        
        if self.modalPresentationStyle == .popover {
            self.preferredContentSize = CGSize(width: width, height: height)
        }
        
        if self.showCancelButton {
            self.view.addSubview(cancelButton)
            cancelButton.snp.makeConstraints { make in
                make.centerX.equalTo(self.view.snp.centerX)
                make.width.equalTo(width)
                make.height.equalTo(PhotonActionSheetUX.CancelButtonHeight)
                if #available(iOS 11, *) {
                    let bottomPad: CGFloat
                    if let window = UIApplication.shared.keyWindow, window.safeAreaInsets.bottom != 0  {
                        // for iPhone X and similar 
                        bottomPad = 0
                    } else {
                        bottomPad = PhotonActionSheetUX.Padding
                    }
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-bottomPad)
                } else {
                    make.bottom.equalTo(self.view.snp.bottom).offset(-PhotonActionSheetUX.Padding)
                }
            }
        }
        
        if style == .bottom && self.modalPresentationStyle == .popover {
            // We are showing the menu in a popOver
            self.actions = actions.map({ $0.reversed() }).reversed()
            tableView.frame = CGRect(origin: CGPoint.zero, size: self.preferredContentSize)
            return
        }
        
        tableView.snp.makeConstraints { make in
            make.centerX.equalTo(self.view.snp.centerX)
            switch style {
            case .bottom:
                make.bottom.equalTo(cancelButton.snp.top).offset(-PhotonActionSheetUX.Padding)
            case .centered:
                make.centerY.equalTo(self.view.snp.centerY)
            }
            make.width.equalTo(width)
            make.height.equalTo(min(height, view.bounds.height - PhotonActionSheetUX.CancelButtonHeight - (PhotonActionSheetUX.Padding * 6)))
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
    
    fileprivate func actionSheetHeight() -> CGFloat {
        let count = actions.reduce(0) { $1.count + $0 }
        let headerHeight = (style == .centered) ? PhotonActionSheetUX.HeaderHeight : 0
        let separatorHeight = actions.count > 1 ? (actions.count - 1) * Int(PhotonActionSheetUX.SectionVerticalPadding) : 0
        return CGFloat(separatorHeight) + headerHeight + ( PhotonActionSheetUX.TablePadding * 2)  + CGFloat(count) * PhotonActionSheetUX.RowHeight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }
    
    override func updateViewConstraints() {
        if !self.showCancelButton {
            tableView.frame = CGRect(origin: CGPoint.zero, size: self.preferredContentSize)
        }
        super.updateViewConstraints()
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
        let action = actions[indexPath.section][indexPath.row]
        guard let handler = action.handler else {
            self.dismiss(nil)
            return
        }
        self.dismiss(nil)
        return handler(action)
    }
    
    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PhotonActionSheetUX.RowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // If we have multiple sections show a separator for each one except the first.
        if section > 0 {
            return PhotonActionSheetUX.SectionVerticalPadding
        }
        return self.site != nil ? PhotonActionSheetUX.HeaderHeight : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.section][indexPath.row]
        cell.accessibilityIdentifier = action.iconString
        cell.tintColor = action.isEnabled ? UIConstants.SystemBlueColor : self.tintColor
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // If we have multiple sections show a separator for each one except the first.
        if section > 0 {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
        }
        guard let site = site else {
            return nil
        }
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.HeaderName) as! PhotonActionSheetHeaderView
        header.tintColor = self.tintColor
        header.configureWithSite(site)
        return header
    }
}

private class PhotonActionSheetHeaderView: UITableViewHeaderFooterView {
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
        siteImageView.contentMode = UIViewContentMode.center
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
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView).offset(PhotonActionSheetHeaderView.Padding)
            make.size.equalTo(PhotonActionSheetUX.SiteImageViewSize)
        }
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.spacing = PhotonActionSheetHeaderView.VerticalPadding
        stackView.alignment = .leading
        stackView.axis = .vertical
        
        contentView.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(PhotonActionSheetHeaderView.Padding)
            make.trailing.equalTo(contentView).inset(PhotonActionSheetHeaderView.Padding)
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
    
    func configureWithSite(_ site: Site) {
        self.siteImageView.setFavicon(forSite: site) { (color, url) in
            self.siteImageView.backgroundColor = color
            self.siteImageView.image = self.siteImageView.image?.createScaled(PhotonActionSheetUX.IconSize)
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
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
        separatorLineView.backgroundColor = UIColor.lightGray
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

private class PhotonActionSheetCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        titleLabel.minimumScaleFactor = 0.75 // Scale the font if we run out of space
        titleLabel.textColor = PhotonActionSheetCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()
    
    lazy var statusIcon: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.scaleAspectFit
        siteImageView.clipsToBounds = true
        siteImageView.layer.cornerRadius = PhotonActionSheetCellUX.CornerRadius
        return siteImageView
    }()
    
    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = PhotonActionSheetCellUX.SelectedOverlayColor
        selectedOverlay.isHidden = true
        return selectedOverlay
    }()
    
    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        self.statusIcon.image = nil
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        isAccessibilityElement = true
        
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)
        backgroundColor = .clear
        
        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(statusIcon.snp.trailing).offset(16)
            make.trailing.equalTo(contentView)
            make.centerY.equalTo(contentView)
        }
        
        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(PhotonActionSheetCellUX.StatusIconSize)
            make.leading.equalTo(contentView).offset(16)
            make.centerY.equalTo(contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell(_ label: String, imageString: String) {
        titleLabel.text = label
        titleLabel.textColor = self.tintColor
        accessibilityIdentifier = imageString
        accessibilityLabel = label
        if let image = UIImage(named: imageString)?.withRenderingMode(.alwaysTemplate) {
            statusIcon.image = image
            statusIcon.tintColor = self.tintColor
        }
    }
}

