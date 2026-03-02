// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class AccentColorCell: UICollectionViewCell, ThemeApplicable {
    static let reuseIdentifier = "AccentColorCell"

    private lazy var colorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = UX.swatchSize / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private lazy var customIconView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let imageView = UIImageView(image: UIImage(systemName: "plus", withConfiguration: config))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private struct UX {
        static let swatchSize: CGFloat = 40
        static let checkmarkSize: CGFloat = 16
        static let selectedBorderWidth: CGFloat = 3
        static let unselectedBorderWidth: CGFloat = 0.5
        static let spacing: CGFloat = 4
    }

    private var isAccentSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(colorView)
        colorView.addSubview(checkmarkImageView)
        colorView.addSubview(customIconView)

        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: UX.swatchSize),
            colorView.heightAnchor.constraint(equalToConstant: UX.swatchSize),

            checkmarkImageView.centerXAnchor.constraint(equalTo: colorView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: colorView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: UX.checkmarkSize),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: UX.checkmarkSize),

            customIconView.centerXAnchor.constraint(equalTo: colorView.centerXAnchor),
            customIconView.centerYAnchor.constraint(equalTo: colorView.centerYAnchor),
        ])
    }

    func configure(accentColor: AccentColor, isSelected: Bool) {
        isAccentSelected = isSelected
        colorView.backgroundColor = accentColor.swatchColor
        checkmarkImageView.isHidden = !isSelected
        customIconView.isHidden = true

        updateBorder()
    }

    func configureAsCustom(color: UIColor?, isSelected: Bool) {
        isAccentSelected = isSelected

        if let color = color {
            colorView.backgroundColor = color
            checkmarkImageView.isHidden = !isSelected
            customIconView.isHidden = true
        } else {
            colorView.backgroundColor = .systemGray5
            checkmarkImageView.isHidden = true
            customIconView.isHidden = false
        }

        updateBorder()
    }

    private func updateBorder() {
        if isAccentSelected {
            colorView.layer.borderWidth = UX.selectedBorderWidth
            colorView.layer.borderColor = UIColor.white.cgColor
            // Add outer ring via shadow
            colorView.layer.shadowColor = colorView.backgroundColor?.cgColor
            colorView.layer.shadowOffset = .zero
            colorView.layer.shadowRadius = 4
            colorView.layer.shadowOpacity = 0.6
            colorView.clipsToBounds = false
        } else {
            colorView.layer.borderWidth = UX.unselectedBorderWidth
            colorView.layer.borderColor = UIColor.separator.cgColor
            colorView.layer.shadowOpacity = 0
            colorView.clipsToBounds = true
        }
    }

    func applyTheme(theme: Theme) {
        if !isAccentSelected {
            colorView.layer.borderColor = theme.colors.borderPrimary.cgColor
        }
        customIconView.tintColor = theme.colors.iconSecondary
    }

    override var isAccessibilityElement: Bool {
        get { return true }
        set {}
    }
}
