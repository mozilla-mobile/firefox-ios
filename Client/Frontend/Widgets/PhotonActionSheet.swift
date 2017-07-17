/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit
import Shared

private struct PhotonActionSheetUX {
    static let MaxWidth: CGFloat = 375
    static let Padding: CGFloat = 14
    static let HeaderHeight: CGFloat = 80
    static let RowHeight: CGFloat = 56
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor(rgb: 0x353535)
    static let DescriptionLabelColor = UIColor(colorString: "919191")
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3
    static let BorderWidth: CGFloat = 0.5
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
    static let SiteImageViewSize = 52
    static let IconSize = CGSize(width: 32, height: 32)
    static let HeaderName  = "PhotonActionSheetHeaderView"
    static let CellName = "PhotonActionSheetCell"
}

public struct PhotonActionSheetItem {
    public fileprivate(set) var title: String
    public fileprivate(set) var iconString: String
    public fileprivate(set) var handler: ((PhotonActionSheetItem) -> Void)?
}

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    fileprivate(set) var actions: [PhotonActionSheetItem]

    private var site: Site
    private var tableView = UITableView()

    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(PhotonActionSheet.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    init(site: Site, actions: [PhotonActionSheetItem]) {
        self.site = site
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyBackgroundBlur()
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetUX.CellName)
        tableView.register(PhotonActionSheetHeaderView.self, forHeaderFooterViewReuseIdentifier: PhotonActionSheetUX.HeaderName)
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.isScrollEnabled = true
        tableView.bounces = false
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        let width = min(self.view.frame.size.width, PhotonActionSheetUX.MaxWidth) - (PhotonActionSheetUX.Padding * 2)

        tableView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
            make.width.equalTo(width)
            setHeightConstraint(make)
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

    fileprivate func setHeightConstraint(_ make: ConstraintMaker) {
        make.height.lessThanOrEqualTo(view.bounds.height)
        make.height.equalTo(PhotonActionSheetUX.HeaderHeight + CGFloat(actions.count) * PhotonActionSheetUX.RowHeight).priority(10)
    }

    func dismiss(_ gestureRecognizer: UIGestureRecognizer?) {
        self.dismiss(animated: true, completion: nil)
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func updateViewConstraints() {
        tableView.snp.updateConstraints { make in
            setHeightConstraint(make)
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
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let action = actions[indexPath.row]
        guard let handler = actions[indexPath.row].handler else {
            self.dismiss(nil)
            return
        }
        self.dismiss(nil)
        return handler(action)
    }

    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PhotonActionSheetUX.RowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return PhotonActionSheetUX.HeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetUX.CellName, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.row]
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: PhotonActionSheetUX.HeaderName) as! PhotonActionSheetHeaderView
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
        titleLabel.textColor = PhotonActionSheetUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.MediumSizeRegularWeightAS
        titleLabel.textColor = PhotonActionSheetUX.DescriptionLabelColor
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

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        isAccessibilityElement = true

        contentView.backgroundColor = UIConstants.PanelBackgroundColor
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

private class PhotonActionSheetCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.LargeSizeRegularWeightAS
        titleLabel.minimumScaleFactor = 0.8 // Scale the font if we run out of space
        titleLabel.textColor = PhotonActionSheetCellUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale

        isAccessibilityElement = true

        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)

        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.lightGray
        contentView.addSubview(separatorLineView)

        separatorLineView.snp.makeConstraints { make in
            make.leading.top.trailing.equalTo(self)
            make.height.equalTo(0.25)
        }

        selectedOverlay.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(12)
            make.trailing.equalTo(statusIcon.snp.leading)
            make.centerY.equalTo(contentView)
        }

        statusIcon.snp.makeConstraints { make in
            make.size.equalTo(PhotonActionSheetCellUX.StatusIconSize)
            make.trailing.equalTo(contentView).inset(12)
            make.centerY.equalTo(contentView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureCell(_ label: String, imageString: String) {
        titleLabel.text = label

        if let uiImage = UIImage(named: imageString) {
            let image = uiImage.withRenderingMode(.alwaysTemplate)
            statusIcon.image = image
            statusIcon.tintColor = UIConstants.SystemBlueColor
        }
    }
}

