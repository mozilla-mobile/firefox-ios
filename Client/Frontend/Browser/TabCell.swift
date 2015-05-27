/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

private class TabContentViewUX {
    static let TitleMargin = CGFloat(6)
    static let CloseButtonInset = CGFloat(10)
}

class TabCell: UICollectionViewCell {
    static let Identifier = "TabCellIdentifier"

    var expanded: Bool {
        get {
            return tabView.expanded
        }
        set {
            tabView.expanded = newValue
        }
    }

    var closeButton: UIButton {
        return tabView.closeButton
    }

    lazy var animator: SwipeAnimator = {
        return SwipeAnimator(animatingView: self.tabView, containerView: self)
    }()

    lazy private var tabView: TabContentView = {
        let tabView = TabContentView()
        tabView.setTranslatesAutoresizingMaskIntoConstraints(false)
        return tabView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.tabView)
        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: "SELcloseWithoutGesture")
        ]

        tabView.snp_makeConstraints { make in
            make.top.left.right.bottom.equalTo(self)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func storeSnapshotForHeader(header: UIView?) {
        tabView.headerSnapshot = snapshotForView(header)
    }

    func storeSnapshotForFooter(footer: UIView?) {
        tabView.footerSnapshot = snapshotForView(footer)
    }

    func configureCellWithTab(tab: Browser?) {
        if let tab = tab {
            tabView.titleText.text = tab.displayTitle
            accessibilityLabel = tab.displayTitle
            isAccessibilityElement = true

            if let favIconURLString = tab.displayFavicon?.url {
                tabView.favicon.sd_setImageWithURL(NSURL(string: favIconURLString))
            } else {
                tabView.favicon.image = UIImage(named: "defaultFavicon")
            }
            tabView.background.image = tab.screenshot
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.animator.originalCenter = self.tabView.center
    }

    private func snapshotForView(view: UIView?) -> UIView? {
        if let view = view {
            let oldAlpha = view.alpha
            view.alpha = 1
            let snapshot = view.snapshotViewAfterScreenUpdates(true)
            view.alpha = oldAlpha
            return snapshot
        } else {
            return nil
        }
    }
}

/**
*  Used to display the content within a Tab cell that's shown in the TabTrayController
*/
private class TabContentView: UIView {

    lazy var background: UIImageViewAligned = {
        let browserImageView = UIImageViewAligned()
        browserImageView.contentMode = UIViewContentMode.ScaleAspectFill
        browserImageView.clipsToBounds = true
        browserImageView.userInteractionEnabled = false
        browserImageView.backgroundColor = UIColor.whiteColor()
        browserImageView.alignLeft = true
        browserImageView.alignTop = true
        return browserImageView
    }()

    lazy var titleText: UILabel = {
        let titleText = UILabel()
        titleText.textColor = TabTrayControllerUX.TabTitleTextColor
        titleText.backgroundColor = UIColor.clearColor()
        titleText.textAlignment = NSTextAlignment.Left
        titleText.userInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.font = TabTrayControllerUX.TabTitleTextFont
        return titleText
    }()

    lazy var titleContainer: UIVisualEffectView = {
        let title = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        title.layer.shadowColor = UIColor.blackColor().CGColor
        title.layer.shadowOpacity = 0.2
        title.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        title.layer.shadowRadius = 0
        title.clipsToBounds = true
        return title
    }()

    lazy var favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.backgroundColor = UIColor.clearColor()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        return favicon
    }()

    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        closeButton.imageEdgeInsets = UIEdgeInsets(
            top: TabContentViewUX.CloseButtonInset,
            left: TabContentViewUX.CloseButtonInset,
            bottom: TabContentViewUX.CloseButtonInset,
            right: TabContentViewUX.CloseButtonInset)
        return closeButton
    }()

    var headerSnapshot: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let snapshot = headerSnapshot {
                insertSubview(snapshot, belowSubview: background)
                headerSnapshotHeight = snapshot.frame.size.height
            }
            setNeedsUpdateConstraints()
        }
    }

    var footerSnapshot: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let snapshot = footerSnapshot {
                insertSubview(snapshot, belowSubview: background)
                footerSnapshotHeight = snapshot.frame.size.height
            }
            setNeedsUpdateConstraints()
        }
    }

    private var headerSnapshotHeight: CGFloat?
    private var footerSnapshotHeight: CGFloat?

    private lazy var innerBorder: InnerStrokedView = {
        return InnerStrokedView()
    }()

    var expanded: Bool = false {
        didSet {
            titleContainer.alpha = expanded ? 0 : 1
            innerBorder.alpha = expanded ? 0 : 1
            titleContainerHeight?.updateOffset(expanded ? 0 : TabTrayControllerUX.TextBoxHeight)

            if let headerSnapshot = headerSnapshot, let offset = headerSnapshotHeight {
                headerHeight?.updateOffset(expanded ? offset : 0)
            }

            if let footerSnapshot = footerSnapshot, let offset = footerSnapshotHeight {
                footerHeight?.updateOffset(expanded ? -offset : 0)
            }

            setNeedsLayout()
        }
    }

    private var titleContainerHeight: Constraint?
    private var headerHeight: Constraint?
    private var footerHeight: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = TabTrayControllerUX.CornerRadius
        clipsToBounds = true
        opaque = true

        titleContainer.addSubview(closeButton)
        titleContainer.addSubview(titleText)
        titleContainer.addSubview(favicon)

        addSubview(background)
        addSubview(titleContainer)
        addSubview(innerBorder)

        setupConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()

        if let headerSnapshot = headerSnapshot, let height = headerSnapshotHeight {
            let headerRatio = height / headerSnapshot.frame.size.width
            headerSnapshot.snp_remakeConstraints { make in
                make.top.left.right.equalTo(self)
                make.height.equalTo(headerSnapshot.snp_width).multipliedBy(headerRatio)
            }
        }

        if let footerSnapshot = footerSnapshot, let height = footerSnapshotHeight {
            let footerRatio = height / footerSnapshot.frame.size.width
            footerSnapshot.snp_remakeConstraints { make in
                make.bottom.left.right.equalTo(self)
                make.height.equalTo(footerSnapshot.snp_width).multipliedBy(footerRatio)
            }
        }
    }

    private func setupConstraints() {
        background.snp_makeConstraints { make in
            self.headerHeight = make.top.equalTo(self).constraint
            self.footerHeight = make.bottom.equalTo(self).constraint
            make.left.right.equalTo(self)
        }

        titleContainer.snp_makeConstraints { make in
            make.top.left.right.equalTo(background)
            self.titleContainerHeight = make.height.equalTo(TabTrayControllerUX.TextBoxHeight).constraint
        }

        favicon.snp_makeConstraints { make in
            make.centerY.equalTo(self.titleContainer)
            make.left.equalTo(self.titleContainer).offset(TabContentViewUX.TitleMargin)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
        }

        closeButton.snp_makeConstraints { make in
            make.centerY.equalTo(self.titleContainer)
            make.right.equalTo(self.titleContainer)
            make.size.equalTo(self.titleContainer.snp_height)
        }

        titleText.snp_makeConstraints { make in
            make.centerY.equalTo(self.titleContainer)
            make.leading.equalTo(self.favicon.snp_right).offset(TabContentViewUX.TitleMargin)
            make.trailing.equalTo(self.closeButton.snp_left).offset(-TabContentViewUX.TitleMargin)
            make.height.equalTo(self.titleContainer)
        }

        innerBorder.snp_makeConstraints { make in
            make.top.left.right.bottom.equalTo(background)
        }
    }
}

// A transparent view with a rectangular border with rounded corners, stroked
// with a semi-transparent white border.
private class InnerStrokedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        userInteractionEnabled = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let strokeWidth = CGFloat(1)
        let halfWidth = strokeWidth / 2

        let path = UIBezierPath(roundedRect: CGRect(x: halfWidth,
            y: halfWidth,
            width: rect.width - strokeWidth,
            height: rect.height - strokeWidth),
            cornerRadius: TabTrayControllerUX.CornerRadius)
        
        path.lineWidth = strokeWidth
        UIColor.whiteColor().colorWithAlphaComponent(0.2).setStroke()
        path.stroke()
    }
}