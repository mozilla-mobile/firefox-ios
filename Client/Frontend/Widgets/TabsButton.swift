/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

private struct DefaultUX {
    static let titleColor: UIColor = UIColor.blackColor()
    static let titleBackgroundColor: UIColor = UIColor.whiteColor()
    static let cornerRadius: CGFloat = 2
    static let titleFont: UIFont = UIConstants.DefaultSmallFontBold
    static let borderStrokeWidth: CGFloat = 0
    static let borderColor: UIColor = UIColor.clearColor()
    static let titleInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
}

class TabsButton: UIControl {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DefaultUX.titleFont
        label.textColor = DefaultUX.titleColor
        label.layer.cornerRadius = DefaultUX.cornerRadius
        label.textAlignment = NSTextAlignment.Center
        label.userInteractionEnabled = false
        return label
    }()

    private lazy var labelBackground: UIView = {
        let background = UIView()
        background.backgroundColor = DefaultUX.titleBackgroundColor
        background.layer.cornerRadius = DefaultUX.cornerRadius
        background.userInteractionEnabled = false
        return background
    }()

    private lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = DefaultUX.borderStrokeWidth
        border.color = DefaultUX.borderColor
        border.cornerRadius = DefaultUX.cornerRadius
        border.userInteractionEnabled = false
        return border
    }()

    private var buttonInsets: UIEdgeInsets = DefaultUX.titleInsets

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(labelBackground)
        addSubview(borderView)
        addSubview(titleLabel)
    }

    override func updateConstraints() {
        super.updateConstraints()
        labelBackground.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
        borderView.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
        titleLabel.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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