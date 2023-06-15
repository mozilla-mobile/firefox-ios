// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SnapKit
import Shared
import Common

class TabsButton: UIButton, ThemeApplicable {
    struct UX {
        static let cornerRadius: CGFloat = 2
        static let titleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
        static let insideButtonSize = 24
    }

    private var selectedTintColor: UIColor!
    private var unselectedTintColor: UIColor!
    private var theme: Theme?

    // When all animations are completed, this is the most-recently assigned tab count that is shown.
    // updateTabCount() can be called in rapid succession, this ensures only final tab count is displayed.
    private var countToBe = "1"

    // Re-entrancy guard to ensure the function is complete before starting another animation.
    private var isUpdatingTabCount = false

    override var transform: CGAffineTransform {
        didSet {
            clonedTabsButton?.transform = transform
        }
    }

    override var isHighlighted: Bool {
        didSet {
            updateHighlightColors(isHighlighted: isHighlighted)
        }
    }

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UX.titleFont
        label.layer.cornerRadius = UX.cornerRadius
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        return label
    }()

    private lazy var insideButton: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var labelBackground: UIView = {
        let background = UIView()
        background.layer.cornerRadius = UX.cornerRadius
        background.isUserInteractionEnabled = false
        background.backgroundColor = .clear
        return background
    }()

    private lazy var borderView: UIImageView = {
        let border = UIImageView(image: UIImage(named: ImageIdentifiers.navTabCounter)?.withRenderingMode(.alwaysTemplate))
        return border
    }()

    // Used to temporarily store the cloned button so we can respond to layout changes during animation
    private weak var clonedTabsButton: TabsButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubview(labelBackground)
        insideButton.addSubview(borderView)
        insideButton.addSubview(countLabel)
        addSubview(insideButton)
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        selectedTintColor = tintColor
        unselectedTintColor = tintColor
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
            make.size.equalTo(UX.insideButtonSize)
            make.center.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createTabsButton() -> TabsButton {
        let button = TabsButton()

        button.accessibilityLabel = accessibilityLabel
        button.countLabel.text = countLabel.text

        // Copy all of the stylable properties over to the new TabsButton
        button.countLabel.font = countLabel.font
        button.countLabel.layer.cornerRadius = countLabel.layer.cornerRadius
        button.labelBackground.layer.cornerRadius = labelBackground.layer.cornerRadius
        if let theme {
            button.applyTheme(theme: theme)
        }

        return button
    }

    func updateTabCount(_ count: Int,
                        animated: Bool = true) {
        let count = max(count, 1)
        let currentCount = self.countLabel.text
        let infinity = "\u{221E}"
        countToBe = (count < 100) ? count.description : infinity

        // Only animate a tab count change if the tab count has actually changed
        let hasDescriptionChanged = (clonedTabsButton?.countLabel.text ?? count.description) != count.description
        guard currentCount != count.description || hasDescriptionChanged else { return }

        // Re-entrancy guard: if this code is running just update the tab count value without starting another animation.
        if isUpdatingTabCount {
            if let clone = self.clonedTabsButton {
                clone.countLabel.text = countToBe
                clone.accessibilityValue = countToBe
            }
            return
        }
        isUpdatingTabCount = true

        if self.clonedTabsButton != nil {
            self.clonedTabsButton?.layer.removeAllAnimations()
            self.clonedTabsButton?.removeFromSuperview()
            insideButton.layer.removeAllAnimations()
        }

        let newTabsButton = createTabsButton()
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

        animateButton(newTabsButton: newTabsButton, animated: animated)
    }

    private func animateButton(newTabsButton: TabsButton, animated: Bool) {
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
            UIView.animate(withDuration: 1.5,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.0,
                           options: [],
                           animations: animate,
                           completion: completion)
        } else {
            completion(true)
        }
    }

    @objc
    func cloneDidClickTabs() {
        sendActions(for: .touchUpInside)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        self.theme = theme
        borderView.tintColor = theme.colors.iconPrimary
        countLabel.textColor = theme.colors.iconPrimary

        selectedTintColor = theme.colors.actionPrimary
        unselectedTintColor = theme.colors.iconPrimary
    }

    private func updateHighlightColors(isHighlighted: Bool) {
        borderView.tintColor = isHighlighted ? selectedTintColor: unselectedTintColor
        countLabel.textColor = isHighlighted ? selectedTintColor: unselectedTintColor
    }
}
