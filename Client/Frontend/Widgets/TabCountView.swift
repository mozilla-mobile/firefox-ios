/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

private struct TabCountViewThemes {
    static let titleColor: UIColor = .blackColor()
    static let titleBackgroundColor: UIColor = .whiteColor()
    static let cornerRadius: CGFloat = 2
    static let titleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
    static let borderStrokeWidth: CGFloat = 1
    static let borderColor: UIColor = .clearColor()

    static let normalTheme: Theme = {
        var theme = Theme()
        theme.borderColor = borderColor
        theme.borderWidth = borderStrokeWidth
        theme.font = titleFont
        theme.backgroundColor = titleBackgroundColor
        theme.textColor = titleColor
        theme.highlightButtonColor = titleColor
        theme.highlightTextColor = titleBackgroundColor
        theme.highlightBorderColor = titleBackgroundColor
        return theme
    }()

    static let privateTheme: Theme = {
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModePurple
        theme.borderWidth = borderStrokeWidth
        theme.font = UIConstants.DefaultChromeBoldFont
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.textColor = UIConstants.PrivateModePurple
        theme.highlightButtonColor = UIConstants.PrivateModePurple
        theme.highlightTextColor = titleColor
        theme.highlightBorderColor = UIConstants.PrivateModePurple
        return theme
    }()

    static let themes: [String: Theme] = {
        return [
            Theme.PrivateMode: privateTheme,
            Theme.NormalMode: normalTheme
        ]
    }()
}

/// Custom view that renders a rounded rect and the number of tabs inside the TabCountToolbarButton
class TabCountView: UIView {
    var count: Int {
        get {
            return Int(countLabel.text ?? "") ?? 0
        }
        set(value) {
            countLabel.text = String(value)
        }
    }

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = false
        return label
    }()

    private lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = TabsButtonUX.BorderStrokeWidth
        border.cornerRadius = TabsButtonUX.CornerRadius
        border.userInteractionEnabled = false
        return border
    }()

    convenience init(count: Int) {
        self.init(frame: CGRect.zero)
        self.count = count
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        userInteractionEnabled = false
        
        addSubview(borderView)
        addSubview(countLabel)

        layer.cornerRadius = TabsButtonUX.CornerRadius

        borderView.snp_makeConstraints { $0.edges.equalTo(self) }
        countLabel.snp_makeConstraints { $0.center.equalTo(self) }

        backgroundColor = .whiteColor()

        applyTheme(Theme.NormalMode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 22, height: 22)
    }
}

// MARK: - Themeable
extension TabCountView: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = TabCountViewThemes.themes[themeName] else {
            return
        }

        layer.borderColor = theme.borderColor!.CGColor
        layer.borderWidth = theme.borderWidth!
        countLabel.font = theme.font
        backgroundColor = theme.backgroundColor
        countLabel.textColor = theme.textColor

//        theme.highlightButtonColor = UIConstants.PrivateModePurple
//        theme.highlightTextColor = titleColor
//        theme.highlightBorderColor = UIConstants.PrivateModePurple
    }
}