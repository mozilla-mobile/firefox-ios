/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared

struct TabsButtonUX {
    static let CornerRadius: CGFloat = 2
    static let TitleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
    static let BorderStrokeWidth: CGFloat = 1.5
}

class TabsButton: UIButton {
    var textColor = UIColor.Photon.Blue40 {
        didSet {
            countLabel.textColor = textColor
            borderView.color = textColor
        }
    }
    var titleBackgroundColor = UIColor.Photon.Blue40 {
        didSet {
            labelBackground.backgroundColor = titleBackgroundColor
        }
    }
    var highlightTextColor: UIColor?
    var highlightBackgroundColor: UIColor?
    var inTopTabs = false

    // When all animations are completed, this is the most-recently assigned tab count that is shown.
    // updateTabCount() can be called in rapid succession, this ensures only final tab count is displayed.
    private var countToBe = "1"

    // Re-entrancy guard to ensure the function is complete before starting another animation.
    private var isUpdatingTabCount = false

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
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)
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
        countToBe = (count < 100) ? count.description : infinity

        // only animate a tab count change if the tab count has actually changed
        guard currentCount != count.description || (clonedTabsButton?.countLabel.text ?? count.description) != count.description else {
            return
        }

        // Re-entrancy guard: if this code is running just update the tab count value without starting another animation.
        if isUpdatingTabCount {
            if let clone = self.clonedTabsButton {
                clone.countLabel.text = countToBe
                clone.accessibilityValue = countToBe
            }
            return
        }
        isUpdatingTabCount = true

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
            self.accessibilityLabel = .TabsButtonShowTabsAccessibilityLabel
            self.countLabel.text = self.countToBe
            self.accessibilityValue = self.countToBe
            self.isUpdatingTabCount = false
        }

        if animated {
            UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: [], animations: animate, completion: completion)
        } else {
            completion(true)
        }

    }
    @objc func cloneDidClickTabs() {
        sendActions(for: .touchUpInside)
    }
}

extension TabsButton: Themeable {
    func applyTheme() {
        if inTopTabs {
            textColor = UIColor.theme.topTabs.buttonTint
        } else {
            textColor = UIColor.theme.browser.tint
        }
    }
}

