/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

struct TabsButtonUX {
    static let TitleColor: UIColor = UIColor.blackColor()
    static let TitleBackgroundColor: UIColor = UIColor.whiteColor()
    static let CornerRadius: CGFloat = 2
    static let TitleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
    static let BorderStrokeWidth: CGFloat = 1
    static let BorderColor: UIColor = UIColor.clearColor()
    static let TitleInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModePurple
        theme.borderWidth = BorderStrokeWidth
        theme.font = UIConstants.DefaultChromeBoldFont
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.textColor = UIConstants.PrivateModePurple
        theme.insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        theme.highlightButtonColor = UIConstants.PrivateModePurple
        theme.highlightTextColor = TabsButtonUX.TitleColor
        theme.highlightBorderColor = UIConstants.PrivateModePurple
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor = BorderColor
        theme.borderWidth = BorderStrokeWidth
        theme.font = TitleFont
        theme.backgroundColor = TitleBackgroundColor
        theme.textColor = TitleColor
        theme.insets = TitleInsets
        theme.highlightButtonColor = TabsButtonUX.TitleColor
        theme.highlightTextColor = TabsButtonUX.TitleBackgroundColor
        theme.highlightBorderColor = TabsButtonUX.TitleBackgroundColor
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class TabsButton: UIControl {
    private var theme: Theme = TabsButtonUX.Themes[Theme.NormalMode]!
    
    override var highlighted: Bool {
        didSet {
            if highlighted {
                borderColor = theme.highlightBorderColor!
                titleBackgroundColor = theme.highlightButtonColor
                textColor = theme.highlightTextColor
            } else {
                borderColor = theme.borderColor!
                titleBackgroundColor = theme.backgroundColor
                textColor = theme.textColor
            }
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = false
        return label
    }()

    lazy var insideButton: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.userInteractionEnabled = false
        return view
    }()

    private lazy var labelBackground: UIView = {
        let background = UIView()
        background.layer.cornerRadius = TabsButtonUX.CornerRadius
        background.userInteractionEnabled = false
        return background
    }()

    private lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = TabsButtonUX.BorderStrokeWidth
        border.cornerRadius = TabsButtonUX.CornerRadius
        border.userInteractionEnabled = false
        return border
    }()

    private var buttonInsets: UIEdgeInsets = TabsButtonUX.TitleInsets

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubview(labelBackground)
        insideButton.addSubview(borderView)
        insideButton.addSubview(titleLabel)
        addSubview(insideButton)
        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton
    }

    override func updateConstraints() {
        super.updateConstraints()
        labelBackground.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        borderView.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        titleLabel.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        insideButton.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clone() -> UIView {
        let button = TabsButton()

        button.accessibilityLabel = accessibilityLabel
        button.titleLabel.text = titleLabel.text

        // Copy all of the styable properties over to the new TabsButton
        button.titleLabel.font = titleLabel.font
        button.titleLabel.textColor = titleLabel.textColor
        button.titleLabel.layer.cornerRadius = titleLabel.layer.cornerRadius

        button.labelBackground.backgroundColor = labelBackground.backgroundColor
        button.labelBackground.layer.cornerRadius = labelBackground.layer.cornerRadius

        button.borderView.strokeWidth = borderView.strokeWidth
        button.borderView.color = borderView.color
        button.borderView.cornerRadius = borderView.cornerRadius
        return button
    }
}

extension TabsButton: Themeable {
    func applyTheme(themeName: String) {

        guard let theme = TabsButtonUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        borderColor = theme.borderColor!
        borderWidth = theme.borderWidth!
        titleFont = theme.font
        titleBackgroundColor = theme.backgroundColor
        textColor = theme.textColor
        insets = theme.insets!

        self.theme = theme
    }
}

// MARK: UIAppearance
extension TabsButton {
    dynamic var borderColor: UIColor {
        get { return borderView.color }
        set { borderView.color = newValue }
    }

    dynamic var borderWidth: CGFloat {
        get { return borderView.strokeWidth }
        set { borderView.strokeWidth = newValue }
    }

    dynamic var textColor: UIColor? {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

    dynamic var titleFont: UIFont? {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }

    dynamic var titleBackgroundColor: UIColor? {
        get { return labelBackground.backgroundColor }
        set { labelBackground.backgroundColor = newValue }
    }

    dynamic var insets : UIEdgeInsets {
        get { return buttonInsets }
        set {
            buttonInsets = newValue
            setNeedsUpdateConstraints()
        }
    }
}