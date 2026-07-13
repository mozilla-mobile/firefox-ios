// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class FolderSectionHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "FolderSectionHeaderView"

    private struct UX {
        static let horizontalPadding: CGFloat = 16.0
        static let verticalPadding: CGFloat = 8.0
        static let captionBottomPadding: CGFloat = 6.0
        static let chevronSize: CGFloat = 14.0
        static let expandedRotationAngle: CGFloat = .pi / 2
        static let rotationAnimationDuration: TimeInterval = 0.2
    }

    lazy var captionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    lazy var chevronImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var captionHeightConstraint = captionLabel.heightAnchor.constraint(equalToConstant: 0)
    private lazy var titleHeightConstraint = titleLabel.heightAnchor.constraint(equalToConstant: 0)

    var onTap: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupLayout()
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear
        accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.folderSectionHeader
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
        captionLabel.text = nil
        titleLabel.text = nil
        captionHeightConstraint.isActive = true
        titleHeightConstraint.isActive = true
        chevronImageView.isHidden = true
        chevronImageView.transform = .identity
        isUserInteractionEnabled = false
        accessibilityTraits = []
        accessibilityValue = nil
    }

    private func setupLayout() {
        contentView.addSubview(captionLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)

        captionHeightConstraint.isActive = true
        titleHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalPadding),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalPadding),
            captionLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -UX.horizontalPadding),

            titleLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: UX.captionBottomPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.verticalPadding),

            chevronImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalPadding),
            chevronImageView.widthAnchor.constraint(equalToConstant: UX.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: UX.chevronSize)
        ])
    }

    func configure(title: String?,
                   caption: String? = nil,
                   showsChevron: Bool,
                   isExpanded: Bool = false,
                   titleColor: UIColor,
                   captionColor: UIColor = .clear) {
        let hasCaption = !(caption ?? "").isEmpty
        let hasTitle = !(title ?? "").isEmpty

        captionLabel.text = hasCaption ? caption : nil
        captionLabel.textColor = captionColor
        captionHeightConstraint.isActive = !hasCaption

        titleLabel.text = hasTitle ? title : nil
        titleLabel.textColor = titleColor
        titleHeightConstraint.isActive = !hasTitle

        chevronImageView.tintColor = titleColor
        accessibilityLabel = hasTitle ? title : caption

        if showsChevron {
            chevronImageView.isHidden = false
            isUserInteractionEnabled = true
            accessibilityTraits = .button
            accessibilityValue = isExpanded ? .Bookmarks.Menu.EditBookmarkGroupExpandedValue
                                            : .Bookmarks.Menu.EditBookmarkGroupCollapsedValue
            setExpanded(isExpanded, animated: false)
        } else {
            chevronImageView.isHidden = true
            isUserInteractionEnabled = false
            accessibilityTraits = []
            accessibilityValue = nil
        }
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        let transform: CGAffineTransform = expanded
            ? CGAffineTransform(rotationAngle: UX.expandedRotationAngle)
            : .identity
        guard animated else {
            chevronImageView.transform = transform
            return
        }
        UIView.animate(withDuration: UX.rotationAnimationDuration) {
            self.chevronImageView.transform = transform
        }
    }

    @objc
    func handleTap() {
        onTap?()
    }
}
