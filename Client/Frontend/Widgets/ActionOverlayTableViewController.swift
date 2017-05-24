/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import SnapKit

private struct ActionOverlayTableViewUX {
    static let MaxWidth: CGFloat = 375
    static let Padding: CGFloat = 14
    static let HeaderHeight: CGFloat = 74
    static let RowHeight: CGFloat = 56
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black : UIColor(rgb: 0x353535)
    static let DescriptionLabelColor = UIColor(colorString: "919191")
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3
    static let BorderWidth: CGFloat = 0.5
    static let BorderColor = UIColor(white: 0, alpha: 0.1)
    static let SiteImageViewSize = 48
    static let IconSize = CGSize(width: 32, height: 32)
}

class ActionOverlayTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    fileprivate(set) var actions: [ActionOverlayTableViewAction]

    private var site: Site
    private var tableView = UITableView()

    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(ActionOverlayTableViewController.dismiss(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    init(site: Site, actions: [ActionOverlayTableViewAction]) {
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
        view.accessibilityIdentifier = "Action Overlay"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.onDrag
        tableView.register(ActionOverlayTableViewCell.self, forCellReuseIdentifier: "ActionOverlayTableViewCell")
        tableView.register(ActionOverlayTableViewHeader.self, forHeaderFooterViewReuseIdentifier: "ActionOverlayTableViewHeader")
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.isScrollEnabled = true
        tableView.bounces = false
        tableView.layer.cornerRadius = 10
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"

        let width = min(self.view.frame.size.width, ActionOverlayTableViewUX.MaxWidth) - (ActionOverlayTableViewUX.Padding * 2)

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
        make.height.equalTo(ActionOverlayTableViewUX.HeaderHeight + CGFloat(actions.count) * ActionOverlayTableViewUX.RowHeight).priority(10)
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
        return ActionOverlayTableViewUX.RowHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ActionOverlayTableViewUX.HeaderHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActionOverlayTableViewCell", for: indexPath) as! ActionOverlayTableViewCell
        let action = actions[indexPath.row]
        cell.configureCell(action.title, imageString: action.iconString)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ActionOverlayTableViewHeader") as! ActionOverlayTableViewHeader
        header.configureWithSite(site)
        return header
    }
}

class ActionOverlayTableViewHeader: UITableViewHeaderFooterView {
    static let Padding: CGFloat = 12
    static let VerticalPadding: CGFloat = 2

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontMediumBold
        titleLabel.textColor = ActionOverlayTableViewUX.LabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    lazy var descriptionLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFontDescriptionActivityStream
        titleLabel.textColor = ActionOverlayTableViewUX.DescriptionLabelColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    lazy var siteImageView: UIImageView = {
        let siteImageView = UIImageView()
        siteImageView.contentMode = UIViewContentMode.center
        siteImageView.layer.cornerRadius = ActionOverlayTableViewUX.CornerRadius
        siteImageView.layer.borderColor = ActionOverlayTableViewUX.BorderColor.cgColor
        siteImageView.layer.borderWidth = ActionOverlayTableViewUX.BorderWidth
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
            make.leading.equalTo(contentView).offset(ActionOverlayTableViewHeader.Padding)
            make.size.equalTo(ActionOverlayTableViewUX.SiteImageViewSize)
        }

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.spacing = ActionOverlayTableViewHeader.VerticalPadding
        stackView.alignment = .leading
        stackView.axis = .vertical

        contentView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.equalTo(siteImageView.snp.trailing).offset(ActionOverlayTableViewHeader.Padding)
            make.trailing.equalTo(contentView).inset(ActionOverlayTableViewHeader.Padding)
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
            self.siteImageView.image = self.siteImageView.image?.createScaled(ActionOverlayTableViewUX.IconSize)
        }
        self.titleLabel.text = site.title.characters.count <= 1 ? site.url : site.title
        self.descriptionLabel.text = site.tileURL.baseDomain
    }
}
