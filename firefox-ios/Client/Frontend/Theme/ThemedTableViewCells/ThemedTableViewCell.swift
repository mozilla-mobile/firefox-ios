// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class ThemedTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    var viewModel: ThemedTableViewCellViewModel?
    var cellStyle: UITableViewCell.CellStyle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellStyle = style
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // When UITableViewAutomaticDimension is enabled the system calls
    // -systemLayoutSizeFittingSize:withHorizontalFittingPriority:verticalFittingPriority: to calculate the cell height.
    // Unfortunately, it ignores the height of the detailTextLabel in its computation (bug !?).
    // As a result, for UITableViewCellStyleSubtitle the cell height is always going to be too short.
    // So we override to include detailTextLabel height.
    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
        self.layoutSubviews()
        var size = super.systemLayoutSizeFitting(targetSize,
                                                 withHorizontalFittingPriority: horizontalFittingPriority,
                                                 verticalFittingPriority: verticalFittingPriority)
        if cellStyle == .value2 || cellStyle == .value1 {
            if let textLabel = self.textLabel, let detailTextLabel = self.detailTextLabel {
                let detailHeight = detailTextLabel.frame.size.height
                let isValueTextEmpty = detailTextLabel.text?.isEmpty ?? false
                if !isValueTextEmpty { // style = Value1 or Value2
                    let textHeight = textLabel.frame.size.height
                    if detailHeight > textHeight {
                        size.height += detailHeight - textHeight
                    }
                } else { // style = Subtitle, so always add subtitle height
                    size.height += detailHeight
                }
            }
            return size
        } else {
            return size
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        textLabel?.textAlignment = .natural
        textLabel?.font = FXFontStyles.Regular.body.scaledFont()
        detailTextLabel?.text = nil
        accessoryView = nil
        accessoryType = .none
        editingAccessoryView = nil
        editingAccessoryType = .none
        imageView?.image = nil
        contentView.directionalLayoutMargins = .zero
        contentView.subviews.forEach {
            $0.removeFromSuperview()
        }
        subviews.forEach {
            $0.alpha = 1.0
        }
    }

    func applyTheme(theme: Theme) {
        self.viewModel?.setColors(theme: theme)
        // Take view model color if it exists, otherwise fallback to default colors
        textLabel?.textColor = viewModel?.textColor ?? theme.colors.textPrimary
        detailTextLabel?.textColor = viewModel?.detailTextColor ?? theme.colors.textSecondary
        backgroundColor = viewModel?.backgroundColor ?? theme.colors.layer5
        tintColor = viewModel?.tintColor ?? theme.colors.actionPrimary
    }

    func configure(viewModel: ThemedTableViewCellViewModel) {
        self.viewModel = viewModel
    }
}
