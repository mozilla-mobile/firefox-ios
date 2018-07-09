/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

private struct TabsButtonUX {
    static let CornerRadius: CGFloat = 2
    static let TitleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
    static let BorderStrokeWidth: CGFloat = 3
}

class TabsButton: UIButton {
    var privateModeBadge = UIImageView(image: UIImage(imageLiteralResourceName: "privateModeBadge"))

    let privateModeBadgeSize = CGFloat(16)
    let privateModeBadgeOffset = CGFloat(10)

    var textColor = UIColor.clear {
        didSet {
            countLabel.textColor = textColor
            borderView.color = textColor
        }
    }
    var titleBackgroundColor = UIColor.clear {
        didSet {
            labelBackground.backgroundColor = titleBackgroundColor
        }
    }
    var highlightTextColor: UIColor?
    var highlightBackgroundColor: UIColor?

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                borderView.color = titleBackgroundColor
            } else {
                borderView.color = textColor
            }
        }
    }

    override var transform: CGAffineTransform {
        didSet {
            clonedTabsButton?.transform = transform
        }
    }

    lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        return label
    }()

    lazy var insideButton: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
        return view
    }()

    fileprivate lazy var labelBackground: UIView = {
        let background = UIView()
        background.layer.cornerRadius = TabsButtonUX.CornerRadius
        background.isUserInteractionEnabled = false
        return background
    }()

    fileprivate lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = TabsButtonUX.BorderStrokeWidth
        border.cornerRadius = TabsButtonUX.CornerRadius
        border.isUserInteractionEnabled = false
        return border
    }()

    // Used to temporarily store the cloned button so we can respond to layout changes during animation
    fileprivate weak var clonedTabsButton: TabsButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubview(labelBackground)
        insideButton.addSubview(borderView)
        insideButton.addSubview(countLabel)
        addSubview(insideButton)
        addSubview(privateModeBadge)
        privateModeBadge.isHidden = true
        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton
    }

    override func updateConstraints() {
        super.updateConstraints()
        labelBackground.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        borderView.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        countLabel.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        insideButton.snp.remakeConstraints { (make) -> Void in
            make.size.equalTo(24)
            make.center.equalTo(self)
        }

        privateModeBadge.snp.remakeConstraints { make in
            make.size.equalTo(privateModeBadgeSize)
            make.centerX.equalToSuperview().offset(privateModeBadgeOffset)
            make.centerY.equalToSuperview().offset(-privateModeBadgeOffset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override func clone() -> UIView {
        let button = TabsButton()

        button.accessibilityLabel = accessibilityLabel
        button.countLabel.text = countLabel.text

        // Copy all of the styable properties over to the new TabsButton
        button.countLabel.font = countLabel.font
        button.countLabel.textColor = countLabel.textColor
        button.countLabel.layer.cornerRadius = countLabel.layer.cornerRadius

        button.labelBackground.backgroundColor = labelBackground.backgroundColor
        button.labelBackground.layer.cornerRadius = labelBackground.layer.cornerRadius

        button.borderView.strokeWidth = borderView.strokeWidth
        button.borderView.color = borderView.color
        button.borderView.cornerRadius = borderView.cornerRadius

        return button
    }

    func updateTabCount(_ count: Int, animated: Bool = true) {
        let count = max(count, 1)
        let currentCount = self.countLabel.text
        let infinity = "\u{221E}"
        let countToBe = (count < 100) ? count.description : infinity

        // only animate a tab count change if the tab count has actually changed
        if currentCount != count.description || (clonedTabsButton?.countLabel.text ?? count.description) != count.description {
            if let _ = self.clonedTabsButton {
                self.clonedTabsButton?.layer.removeAllAnimations()
                self.clonedTabsButton?.removeFromSuperview()
                insideButton.layer.removeAllAnimations()
            }

            // make a 'clone' of the tabs button
            let newTabsButton = clone() as! TabsButton

            self.clonedTabsButton = newTabsButton
            newTabsButton.frame = self.bounds
            newTabsButton.addTarget(self, action: #selector(cloneDidClickTabs), for: .touchUpInside)
            newTabsButton.countLabel.text = countToBe
            newTabsButton.accessibilityValue = countToBe
            newTabsButton.insideButton.frame = self.insideButton.frame
            newTabsButton.snp.removeConstraints()
            self.addSubview(newTabsButton)
            newTabsButton.snp.makeConstraints { make  in
                make.center.equalTo(self)
            }

            // Instead of changing the anchorPoint of the CALayer, lets alter the rotation matrix math to be
            // a rotation around a non-origin point
            let frame = self.insideButton.frame
            let halfTitleHeight = frame.height / 2
            var newFlipTransform = CATransform3DIdentity
            newFlipTransform = CATransform3DTranslate(newFlipTransform, 0, halfTitleHeight, 0)
            newFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            newFlipTransform = CATransform3DRotate(newFlipTransform, CGFloat(-(Double.pi / 2)), 1.0, 0.0, 0.0)
            newTabsButton.insideButton.layer.transform = newFlipTransform

            var oldFlipTransform = CATransform3DIdentity
            oldFlipTransform = CATransform3DTranslate(oldFlipTransform, 0, halfTitleHeight, 0)
            oldFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            oldFlipTransform = CATransform3DRotate(oldFlipTransform, CGFloat(-(Double.pi / 2)), 1.0, 0.0, 0.0)

            let animate = {
                newTabsButton.insideButton.layer.transform = CATransform3DIdentity
                self.insideButton.layer.transform = oldFlipTransform
                self.insideButton.layer.opacity = 0
            }

            let completion: (Bool) -> Void = { completed in
                let noActiveAnimations = self.insideButton.layer.animationKeys()?.isEmpty ?? true
                if completed || noActiveAnimations {
                    newTabsButton.removeFromSuperview()
                    self.insideButton.layer.opacity = 1
                    self.insideButton.layer.transform = CATransform3DIdentity
                }
                self.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar")
                self.countLabel.text = countToBe
                self.accessibilityValue = countToBe
            }

            if animated {
                UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: animate, completion: completion)
            } else {
                completion(true)
            }
        }
    }
    @objc func cloneDidClickTabs() {
        sendActions(for: .touchUpInside)
    }
}

extension TabsButton: Themeable, PrivateModeUI {
    func applyTheme() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            titleBackgroundColor = UIColor.theme.topTabs.background
            textColor = UIColor.theme.topTabs.buttonTint
        } else {
            titleBackgroundColor = UIColor.theme.browser.background
            textColor = UIColor.theme.browser.tint
        }
    }

    func applyUIMode(isPrivate: Bool) {
        privateModeBadge.isHidden = !isPrivate
    }
}

