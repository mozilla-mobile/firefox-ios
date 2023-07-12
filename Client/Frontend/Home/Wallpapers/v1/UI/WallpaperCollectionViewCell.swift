// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class WallpaperCollectionViewCell: UICollectionViewCell, ReusableCell {
    private struct UX {
        static let cornerRadius: CGFloat = 10
        static let borderWidth: CGFloat = 1
        static let selectedBorderWidth: CGFloat = 3
        static let shadowOffset = CGSize(width: 0, height: 5.0)
        static let shadowOpacity: Float = 0.2
        static let shadowRadius: CGFloat = 4.0
    }

    // MARK: - UI Element
    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private lazy var borderView: UIView = .build { borderView in
        borderView.layer.cornerRadius = WallpaperCollectionViewCell.UX.cornerRadius
        borderView.layer.borderWidth = WallpaperCollectionViewCell.UX.borderWidth
        borderView.backgroundColor = .clear
    }

    private lazy var selectedView: UIView = .build { selectedView in
        selectedView.layer.cornerRadius = WallpaperCollectionViewCell.UX.cornerRadius
        selectedView.layer.borderWidth = WallpaperCollectionViewCell.UX.selectedBorderWidth
        selectedView.backgroundColor = .clear
        selectedView.alpha = 0.0
    }

    private lazy var activityIndicatorView: UIActivityIndicatorView = .build { view in
        view.style = .large
        view.isHidden = true
    }

    // MARK: - Variables
    var viewModel: WallpaperCellViewModel? {
        didSet {
            updateContent()
        }
    }

    override var isSelected: Bool {
        didSet {
            selectedView.alpha = isSelected ? 1.0 : 0.0
        }
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func showDownloading(_ isDownloading: Bool) {
        if isDownloading {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    func setupShadow(theme: Theme) {
        layer.backgroundColor = UIColor.clear.cgColor
        layer.shadowColor = theme.colors.shadowDefault.cgColor
        layer.shadowOffset = WallpaperCollectionViewCell.UX.shadowOffset
        layer.shadowOpacity = WallpaperCollectionViewCell.UX.shadowOpacity
        layer.shadowRadius = WallpaperCollectionViewCell.UX.shadowRadius
        layer.shadowPath = UIBezierPath(
            roundedRect: self.bounds,
            cornerRadius: WallpaperCollectionViewCell.UX.cornerRadius).cgPath
    }
}

// MARK: - Private
private extension WallpaperCollectionViewCell {
    func updateContent() {
        guard let viewModel = viewModel else { return }
        imageView.image = viewModel.image
        accessibilityIdentifier = viewModel.a11yId
        accessibilityLabel = viewModel.a11yLabel
        isAccessibilityElement = true
    }

    func setupView() {
        contentView.addSubview(borderView)
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
        contentView.addSubview(activityIndicatorView)
        contentView.layer.cornerRadius = WallpaperCollectionViewCell.UX.cornerRadius
        contentView.clipsToBounds = true

        NSLayoutConstraint.activate([
            borderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            borderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            borderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}

// MARK: - ThemeApplicable
extension WallpaperCollectionViewCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.layer2
        borderView.layer.borderColor = theme.colors.borderPrimary.cgColor
        selectedView.layer.borderColor = theme.colors.actionPrimary.cgColor
        activityIndicatorView.color = theme.colors.iconSpinner

        setupShadow(theme: theme)
    }
}
