/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct TopTabsSeparatorUX {
    static let Identifier = "Separator"
    static let Width: CGFloat = 1
}

class TopTabsSeparator: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.theme.topTabs.separator
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabsHeaderFooter: UICollectionReusableView {
    let line = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        line.semanticContentAttribute = .forceLeftToRight
        addSubview(line)
        line.backgroundColor = UIColor.theme.topTabs.separator
    }

    func arrangeLine(_ kind: String) {
        line.snp.removeConstraints()
        switch kind {
        case UICollectionView.elementKindSectionHeader:
                line.snp.makeConstraints { make in
                    make.trailing.equalTo(self)
                }
        case UICollectionView.elementKindSectionFooter:
                line.snp.makeConstraints { make in
                    make.leading.equalTo(self)
                }
            default:
                break
        }
        line.snp.makeConstraints { make in
            make.height.equalTo(TopTabsUX.SeparatorHeight)
            make.width.equalTo(TopTabsUX.SeparatorWidth)
            make.top.equalTo(self).offset(TopTabsUX.SeparatorYOffset)
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabCell: UICollectionViewCell, PrivateModeUI {

    static let Identifier = "TopTabCellIdentifier"
    static let ShadowOffsetSize: CGFloat = 2 //The shadow is used to hide the tab separator

    var selectedTab = false {
        didSet {
            backgroundColor = selectedTab ? UIColor.theme.topTabs.tabBackgroundSelected : UIColor.theme.topTabs.tabBackgroundUnselected
            titleText.textColor = selectedTab ? UIColor.theme.topTabs.tabForegroundSelected : UIColor.theme.topTabs.tabForegroundUnselected
            highlightLine.isHidden = !selectedTab
            closeButton.tintColor = selectedTab ? UIColor.theme.topTabs.closeButtonSelectedTab : UIColor.theme.topTabs.closeButtonUnselectedTab
            closeButton.backgroundColor = backgroundColor
            closeButton.layer.shadowColor = backgroundColor?.cgColor
            if selectedTab {
                drawShadow()
            } else {
                self.layer.shadowOpacity = 0
            }
        }
    }

    let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = .left
        titleText.isUserInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.lineBreakMode = .byCharWrapping
        titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        titleText.semanticContentAttribute = .forceLeftToRight
        return titleText
    }()

    let favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        favicon.semanticContentAttribute = .forceLeftToRight
        return favicon
    }()

    let closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage.templateImageNamed("menu-CloseTabs"), for: [])
        closeButton.tintColor = UIColor.Photon.Grey40
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 15, left: TopTabsUX.TabTitlePadding, bottom: 15, right: TopTabsUX.TabTitlePadding)
        closeButton.layer.shadowOpacity = 0.8
        closeButton.layer.masksToBounds = false
        closeButton.layer.shadowOffset = CGSize(width: -TopTabsUX.TabTitlePadding, height: 0)
        closeButton.semanticContentAttribute = .forceLeftToRight
        return closeButton
    }()

    let highlightLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.Photon.Blue60
        line.isHidden = true
        line.semanticContentAttribute = .forceLeftToRight
        return line
    }()

    weak var delegate: TopTabCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        closeButton.addTarget(self, action: #selector(closeTab), for: .touchUpInside)

        contentView.addSubview(titleText)
        contentView.addSubview(closeButton)
        contentView.addSubview(favicon)
        contentView.addSubview(highlightLine)

        favicon.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(TopTabsUX.TabNudge)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
            make.leading.equalTo(self).offset(TopTabsUX.TabTitlePadding)
        }
        titleText.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(closeButton.snp.leading).offset(TopTabsUX.TabTitlePadding)
            make.leading.equalTo(favicon.snp.trailing).offset(TopTabsUX.TabTitlePadding)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(TopTabsUX.TabNudge)
            make.height.equalTo(self)
            make.width.equalTo(self.snp.height).offset(-TopTabsUX.TabTitlePadding)
            make.trailing.equalTo(self.snp.trailing)
        }
        highlightLine.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(-TopTabCell.ShadowOffsetSize)
            make.trailing.equalTo(self).offset(TopTabCell.ShadowOffsetSize)
            make.height.equalTo(TopTabsUX.HighlightLineWidth)
        }

        self.clipsToBounds = false

        applyUIMode(isPrivate: false)
    }

    func applyUIMode(isPrivate: Bool) {
        highlightLine.backgroundColor = UIColor.theme.topTabs.tabSelectedIndicatorBar(isPrivate)
    }

    func configureWith(tab: Tab, isSelected: Bool) {
        applyUIMode(isPrivate: tab.isPrivate)
        self.titleText.text = tab.displayTitle

        if tab.displayTitle.isEmpty {
            if let url = tab.webView?.url, let internalScheme = InternalURL(url) {
                self.titleText.text = Strings.AppMenuNewTabTitleString
                self.accessibilityLabel = internalScheme.aboutComponent
            } else {
                self.titleText.text = tab.webView?.url?.absoluteDisplayString
            }
            
            self.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, self.titleText.text ?? "")
        } else {
            self.accessibilityLabel = tab.displayTitle
            self.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tab.displayTitle)
        }

        self.selectedTab = isSelected
        if let siteURL = tab.url?.displayURL {
            self.favicon.contentMode = .center
            self.favicon.setImageAndBackground(forIcon: tab.displayFavicon, website: siteURL) { [weak self] in
                guard let self = self else { return }
                self.favicon.image = self.favicon.image?.createScaled(CGSize(width: 15, height: 15))
                if self.favicon.backgroundColor == .clear {
                    self.favicon.backgroundColor = .white
                }
            }
        } else {
            self.favicon.image = UIImage(named: "defaultFavicon")
            self.favicon.tintColor = UIColor.theme.tabTray.faviconTint
            self.favicon.contentMode = .scaleAspectFit
            self.favicon.backgroundColor = .clear
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.layer.shadowOpacity = 0
    }

    @objc func closeTab() {
        delegate?.tabCellDidClose(self)
    }

    // When a tab is selected the shadow prevents the tab separators from showing.
    func drawShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = backgroundColor?.cgColor
        self.layer.shadowOpacity  = 1
        self.layer.shadowRadius = 0

        self.layer.shadowPath = UIBezierPath(roundedRect: CGRect(width: self.frame.size.width + (TopTabCell.ShadowOffsetSize * 2), height: self.frame.size.height), cornerRadius: 0).cgPath
        self.layer.shadowOffset = CGSize(width: -TopTabCell.ShadowOffsetSize, height: 0)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }
}

class TopTabFader: UIView {
    lazy var hMaskLayer: CAGradientLayer = {
        let innerColor: CGColor = UIColor.Photon.White100.cgColor
        let outerColor: CGColor = UIColor(white: 1, alpha: 0.0).cgColor
        let hMaskLayer = CAGradientLayer()
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        hMaskLayer.locations = [0.00, 0.005, 0.995, 1.0]
        hMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        hMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        hMaskLayer.anchorPoint = .zero
        return hMaskLayer
    }()

    init() {
        super.init(frame: .zero)
        layer.mask = hMaskLayer
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()

        let widthA = NSNumber(value: Float(CGFloat(8) / frame.width))
        let widthB = NSNumber(value: Float(1 - CGFloat(8) / frame.width))

        hMaskLayer.locations = [0.00, widthA, widthB, 1.0]
        hMaskLayer.frame = CGRect(width: frame.width, height: frame.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabsViewLayoutAttributes: UICollectionViewLayoutAttributes {

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TopTabsViewLayoutAttributes else {
            return false
        }
        return super.isEqual(object)
    }
}
