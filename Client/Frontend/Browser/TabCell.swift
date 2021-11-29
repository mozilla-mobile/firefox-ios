// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class TabCell: UICollectionViewCell, TabTrayCell {

    enum Style {
        case light
        case dark
    }

    static let reuseIdentifier = "TabCellIdentifier"
    static let borderWidth: CGFloat = 3

    lazy var backgroundHolder: UIView = {
        let view = UIView()
        view.layer.cornerRadius = GridTabTrayControllerUX.CornerRadius
        view.clipsToBounds = true
        view.backgroundColor = UIColor.theme.tabTray.cellBackground
        return view
        
    }()

    lazy private var faviconBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteCellUX.CellCornerRadius
        view.layer.borderWidth = TopSiteCellUX.BorderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = TopSiteCellUX.ShadowRadius
        view.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        view.layer.borderColor = TopSiteCellUX.BorderColor.cgColor
        view.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        view.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        return view
    }()

    lazy var screenshotView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.theme.tabTray.screenshotBackground
        return view
    }()
    
    lazy var smallFaviconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        view.layer.cornerRadius = TopSiteCellUX.IconCornerRadius
        view.layer.masksToBounds = true
        return view
    }()

    let titleText: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        label.textColor = UIColor.theme.tabTray.tabTitleText
        return label
    }()

    let favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.backgroundColor = UIColor.clear
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        return favicon
    }()

    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.imageEdgeInsets = UIEdgeInsets(equalInset: GridTabTrayControllerUX.CloseButtonEdgeInset)
        return button
    }()

    var title = UIVisualEffectView(effect: UIBlurEffect(style: UIColor.theme.tabTray.tabTitleBlur))
    var animator: SwipeAnimator?
    var isSelectedTab = false

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.animator = SwipeAnimator(animatingView: self)
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.addSubview(backgroundHolder)
        
        backgroundHolder.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        faviconBG.addSubview(smallFaviconView)
        backgroundHolder.addSubviews(screenshotView, faviconBG)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabTrayCloseAccessibilityCustomAction, target: self.animator, selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        backgroundHolder.addSubview(title)
        title.contentView.addSubview(self.closeButton)
        title.contentView.addSubview(self.titleText)
        title.contentView.addSubview(self.favicon)

        
        NSLayoutConstraint.activate([
//            title.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
//            title.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
//            title.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
//            title.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.TextBoxHeight),
//            
//            favicon.leadingAnchor.constraint(equalTo: title.contentView.leadingAnchor, constant: 6),
//            favicon.topAnchor.constraint(equalTo: self.topAnchor, constant: ((GridTabTrayControllerUX.TextBoxHeight - GridTabTrayControllerUX.FaviconSize) / 2)),
//            favicon.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.TextBoxHeight),
//            favicon.widthAnchor.constraint(equalToConstant: GridTabTrayControllerUX.TextBoxHeight),
//            qrSignInLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//            qrSignInLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            pairImageView.topAnchor.constraint(equalTo: qrSignInLabel.bottomAnchor),
//            pairImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            pairImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
//            pairImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
//
//            instructionsLabel.topAnchor.constraint(equalTo: pairImageView.bottomAnchor),
//            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            instructionsLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
//
//            scanButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 30),
//            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            scanButton.widthAnchor.constraint(equalToConstant: 328),
//            scanButton.heightAnchor.constraint(equalToConstant: 44),
//
//            emailButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 10),
//            emailButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            emailButton.widthAnchor.constraint(equalToConstant: 328),
//            emailButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        title.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backgroundHolder)
            make.height.equalTo(GridTabTrayControllerUX.TextBoxHeight)
        }

        favicon.snp.makeConstraints { make in
            make.leading.equalTo(title.contentView).offset(6)
            make.top.equalTo((GridTabTrayControllerUX.TextBoxHeight - GridTabTrayControllerUX.FaviconSize) / 2)
            make.size.equalTo(GridTabTrayControllerUX.FaviconSize)
        }

        titleText.snp.makeConstraints { (make) in
            make.leading.equalTo(favicon.snp.trailing).offset(6)
            make.trailing.equalTo(closeButton.snp.leading).offset(-6)
            make.centerY.equalTo(title.contentView)
        }

        closeButton.snp.makeConstraints { make in
            make.size.equalTo(GridTabTrayControllerUX.CloseButtonSize)
            make.centerY.trailing.equalTo(title.contentView)
        }

        screenshotView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalTo(backgroundHolder)
            make.bottom.equalTo(backgroundHolder.snp.bottom)
        }
        
        faviconBG.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(TopSiteCellUX.BackgroundSize)
        }
        
        smallFaviconView.snp.makeConstraints { make in
            make.size.equalTo(TopSiteCellUX.IconSize)
            make.center.equalTo(faviconBG)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowPath = CGRect(width: layer.frame.width + (TabCell.borderWidth * 2), height: layer.frame.height + (TabCell.borderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: GridTabTrayControllerUX.CornerRadius+TabCell.borderWidth).cgPath
    }

    func configureWith(tab: Tab, isSelected selected: Bool) {
        isSelectedTab = selected

        titleText.text = getTabTrayTitle(tab: tab)
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint

        if let favIcon = tab.displayFavicon, let url = URL(string: favIcon.url) {
            favicon.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultFavicon"), options: [], completed: nil)
        } else {
            favicon.image = UIImage(named: "defaultFavicon")
            favicon.tintColor = UIColor.theme.tabTray.faviconTint
        }

        if selected {
            setTabSelected(tab.isPrivate)
        } else {
            layer.shadowOffset = .zero
            layer.shadowPath = nil
            layer.shadowOpacity = 0
        }

        faviconBG.isHidden = true

        // Regular screenshot for home or internal url when tab has home screenshot
        if let url = tab.url, let tabScreenshot = tab.screenshot, (url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when home screenshot is present for a regular (non-internal) url
        } else if let url = tab.url, (!url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            setFaviconImage(for: tab, with: smallFaviconView)

        // Tab screenshot when available
        } else if let tabScreenshot = tab.screenshot {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when tab screenshot isn't available
        } else {
            setFaviconImage(for: tab, with: smallFaviconView)
        }
    }

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        layer.shadowOffset = .zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
        isHidden = false
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .left:
            right = false
        case .right:
            right = true
        default:
            return false
        }
        animator?.close(right: right)
        return true
    }

    @objc func close() {
        delegate?.tabCellDidClose(self)
    }

    private func setTabSelected(_ isPrivate: Bool) {
        // This creates a border around a tabcell. Using the shadow creates a border _outside_ of the tab frame.
        layer.shadowColor = (isPrivate ? UIColor.theme.tabTray.privateModePurple : UIConstants.SystemBlueColor).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 0 // A 0 radius creates a solid border instead of a gradient blur
        layer.masksToBounds = false
        // create a frame that is "BorderWidth" size bigger than the cell
        layer.shadowOffset = CGSize(width: -TabCell.borderWidth, height: -TabCell.borderWidth)
        let shadowPath = CGRect(width: layer.frame.width + (TabCell.borderWidth * 2), height: layer.frame.height + (TabCell.borderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: GridTabTrayControllerUX.CornerRadius+TabCell.borderWidth).cgPath
    }

    func setFaviconImage(for tab: Tab, with imageView: UIImageView) {
        if let url = tab.url?.domainURL ?? tab.sessionData?.urls.last?.domainURL {
            imageView.setImageAndBackground(forIcon: tab.displayFavicon, website: url) {}
            faviconBG.isHidden = false
            screenshotView.image = nil
        }
    }
}
