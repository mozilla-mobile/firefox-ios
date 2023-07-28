// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class ThemedTableSectionHeaderFooterView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let titleHorizontalPadding: CGFloat = 15
        static let titleVerticalPadding: CGFloat = 6
        static let titleVerticalLongPadding: CGFloat = 20
    }

    enum TitleAlignment {
        case top
        case bottom

        var topConstraintConstant: CGFloat {
            switch self {
            case .top:
                return UX.titleVerticalPadding
            case .bottom:
                return UX.titleVerticalLongPadding
            }
        }

        var bottomConstraintConstant: CGFloat {
            switch self {
            case .top:
                return -UX.titleVerticalLongPadding
            case .bottom:
                return -UX.titleVerticalPadding
            }
        }
    }

    var titleAlignment: TitleAlignment = .bottom {
        didSet {
            updateTitleAlignmentConstraints()
        }
    }

    lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline, size: 12.0)
        label.numberOfLines = 0
    }

    private lazy var bordersHelper = ThemedHeaderFooterViewBordersHelper()
    private var titleTopConstraint: NSLayoutConstraint!
    private var titleBottomConstraint: NSLayoutConstraint!

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        bordersHelper.initBorders(view: self.contentView)
        setDefaultBordersValues()
        setupInitialConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        bordersHelper.applyTheme(theme: theme)
        contentView.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textSecondary
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, false)
        bordersHelper.showBorder(for: .bottom, false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDefaultBordersValues()
        titleLabel.text = nil
        titleAlignment = .bottom
    }

    private func setupInitialConstraints() {
        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                             constant: UX.titleVerticalLongPadding)
        titleBottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                                   constant: -UX.titleVerticalPadding)

        NSLayoutConstraint.activate([
            titleTopConstraint,
            titleBottomConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.titleHorizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.titleHorizontalPadding),
        ])
    }

    private func updateTitleAlignmentConstraints() {
        titleTopConstraint.constant = titleAlignment.topConstraintConstant
        titleBottomConstraint.constant = titleAlignment.bottomConstraintConstant
    }
}
