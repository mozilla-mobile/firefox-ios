// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

class TabsButton: UIButton, ThemeApplicable {
    struct UX {
        static let cornerRadius: CGFloat = 2
        static let titleFont: UIFont = FXFontStyles.Bold.caption2.systemFont()
        static let insideButtonSize: CGFloat = 24

        // Animation constants
        static let flipAnimationDuration: TimeInterval = 1.5
        static let flipAnimationDelay: TimeInterval = 0
        static let flipAnimationDamping: CGFloat = 0.5
        static let flipAnimationVelocity: CGFloat = 0.0

        // Tab count related constants
        static let defaultCountLabelText: String = "0"
        static let defaultCountToBe: String = "1"
        static let maxTabCountToShowInfinity: Int = 100
        static let infinitySymbol: String = "\u{221E}"
    }

    private var selectedTintColor: UIColor!
    private var unselectedTintColor: UIColor!
    private var theme: Theme?

    // When all animations are completed, this is the most-recently assigned tab count that is shown.
    // updateTabCount() can be called in rapid succession, this ensures only final tab count is displayed.
    private var countToBe = UX.defaultCountToBe

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

    private lazy var countLabel: UILabel = .build { label in
        label.text = UX.defaultCountLabelText
        label.font = UX.titleFont
        label.layer.cornerRadius = UX.cornerRadius
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
    }

    private lazy var insideButton: UIView = .build { view in
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
    }

    private lazy var labelBackground: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    private lazy var borderView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.tab)?.withRenderingMode(.alwaysTemplate)
    }

    // Used to temporarily store the cloned button so we can respond to layout changes during animation
    private weak var clonedTabsButton: TabsButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubviews(labelBackground, borderView, countLabel)
        addSubview(insideButton)
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)

        selectedTintColor = tintColor
        unselectedTintColor = tintColor
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.activate([
            labelBackground.topAnchor.constraint(equalTo: insideButton.topAnchor),
            labelBackground.leadingAnchor.constraint(equalTo: insideButton.leadingAnchor),
            labelBackground.trailingAnchor.constraint(equalTo: insideButton.trailingAnchor),
            labelBackground.bottomAnchor.constraint(equalTo: insideButton.bottomAnchor),

            borderView.topAnchor.constraint(equalTo: insideButton.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: insideButton.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: insideButton.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: insideButton.bottomAnchor),

            countLabel.topAnchor.constraint(equalTo: insideButton.topAnchor),
            countLabel.leadingAnchor.constraint(equalTo: insideButton.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: insideButton.trailingAnchor),
            countLabel.bottomAnchor.constraint(equalTo: insideButton.bottomAnchor),

            insideButton.heightAnchor.constraint(equalToConstant: UX.insideButtonSize),
            insideButton.widthAnchor.constraint(equalToConstant: UX.insideButtonSize),
            insideButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            insideButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
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
        let currentCount = countLabel.text
        let infinity = UX.infinitySymbol
        countToBe = (count < UX.maxTabCountToShowInfinity) ? count.description : infinity

        // Only animate a tab count change if the tab count has actually changed
        let hasDescriptionChanged = (clonedTabsButton?.countLabel.text ?? count.description) != count.description
        guard currentCount != count.description || hasDescriptionChanged else { return }

        // Re-entrancy guard: if this code is running just update the tab count value without
        // starting another animation.
        if isUpdatingTabCount {
            if let clone = clonedTabsButton {
                clone.countLabel.text = countToBe
                clone.accessibilityValue = countToBe
                clone.largeContentTitle = String(format: .TabsButtonShowTabsLargeContentTitle, countToBe)
            }
            return
        }
        isUpdatingTabCount = true

        if clonedTabsButton != nil {
            clonedTabsButton?.layer.removeAllAnimations()
            clonedTabsButton?.removeFromSuperview()
            insideButton.layer.removeAllAnimations()
        }

        let newTabsButton = createTabsButton()
        self.clonedTabsButton = newTabsButton
        newTabsButton.frame = self.bounds
        newTabsButton.addTarget(self, action: #selector(cloneDidClickTabs), for: .touchUpInside)
        newTabsButton.countLabel.text = countToBe
        newTabsButton.accessibilityValue = countToBe
        newTabsButton.largeContentTitle = String(format: .TabsButtonShowTabsLargeContentTitle, countToBe)
        newTabsButton.insideButton.frame = insideButton.frame
        self.addSubview(newTabsButton)
        NSLayoutConstraint.activate([
            newTabsButton.centerXAnchor.constraint(equalTo: newTabsButton.centerXAnchor),
            newTabsButton.centerYAnchor.constraint(equalTo: newTabsButton.centerYAnchor)
        ])

        animateButton(newTabsButton: newTabsButton, animated: animated)
    }

    private func animateButton(newTabsButton: TabsButton, animated: Bool) {
        // Instead of changing the anchorPoint of the CALayer, lets alter the rotation matrix math to be
        // a rotation around a non-origin point
        let frame = insideButton.frame
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
            self.largeContentTitle = String(format: .TabsButtonShowTabsLargeContentTitle, self.countToBe)
            self.countLabel.text = self.countToBe
            self.accessibilityValue = self.countToBe
            self.isUpdatingTabCount = false
        }

        if animated {
            UIView.animate(withDuration: UX.flipAnimationDuration,
                           delay: UX.flipAnimationDelay,
                           usingSpringWithDamping: UX.flipAnimationDamping,
                           initialSpringVelocity: UX.flipAnimationVelocity,
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
        let colors = theme.colors
        borderView.tintColor = colors.iconPrimary
        countLabel.textColor = colors.iconPrimary

        selectedTintColor = colors.actionPrimary
        unselectedTintColor = colors.iconPrimary
    }

    private func updateHighlightColors(isHighlighted: Bool) {
        borderView.tintColor = isHighlighted ? selectedTintColor: unselectedTintColor
        countLabel.textColor = isHighlighted ? selectedTintColor: unselectedTintColor
    }
}
