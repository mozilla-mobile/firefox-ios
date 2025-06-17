// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class SearchBarCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let shadowRadius: CGFloat = 4
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1
        static let cornerRadius: CGFloat = 16
        static let heightPadding: CGFloat = 20
        static let widthPadding: CGFloat = 16
        static let containerPadding: CGFloat = 4
    }

    private let container: UIView = .build { view in
        view.backgroundColor = .white
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var placeholderLabel: UILabel = .build { view in
//        view.text = String.TabLocationURLPlaceholder
        view.font = FXFontStyles.Regular.body.scaledFont()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        container.addSubview(placeholderLabel)
        contentView.addSubview(container)

        container.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.containerPadding),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.containerPadding),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.containerPadding),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.containerPadding),

            placeholderLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: UX.heightPadding),
            placeholderLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -UX.heightPadding),
            placeholderLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: UX.widthPadding),
            placeholderLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -UX.widthPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.cornerRadius
        ).cgPath
    }

    private lazy var blurView: UIView = .build { view in
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        placeholderLabel.textColor = theme.colors.textSecondary
        container.backgroundColor = theme.colors.layer2
        setupShadow(theme: theme)
    }

    func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = UX.shadowRadius
        contentView.layer.shadowOffset = UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = UX.shadowOpacity
    }
}
