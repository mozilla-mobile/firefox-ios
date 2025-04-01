// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// A wrapped UIImageView which displays a plain search engine icon with no tapping features.
final class PlainSearchEngineView: UIView, SearchEngineView, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let cornerRadius: CGFloat = 4
        static let imageViewSize = CGSize(width: 24, height: 24)
    }

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.isAccessibilityElement = true
        imageView.clipsToBounds = true
    }

    private var theme: Theme?
    private var isURLTextFieldCentered = false {
        didSet {
            // We need to call applyTheme to ensure the colors are updated in sync whenever the layout changes.
            guard let theme, isURLTextFieldCentered != oldValue else { return }
            applyTheme(theme: theme)
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ config: LocationViewConfiguration, isLocationTextCentered: Bool, delegate: LocationViewDelegate) {
        isURLTextFieldCentered = isLocationTextCentered
        searchEngineImageView.image = config.searchEngineImage
        configureA11y(config)
    }

    // MARK: - Layout

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = true
        addSubviews(searchEngineImageView)

        NSLayoutConstraint.activate([
            searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.imageViewSize.height),
            searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.imageViewSize.width),
            searchEngineImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            searchEngineImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            searchEngineImageView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            searchEngineImageView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor),
            searchEngineImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            searchEngineImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    // MARK: - Accessibility

    private func configureA11y(_ config: LocationViewConfiguration) {
        searchEngineImageView.accessibilityIdentifier = config.searchEngineImageViewA11yId
        searchEngineImageView.accessibilityLabel = config.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentTitle = config.searchEngineImageViewA11yLabel
        searchEngineImageView.largeContentImage = nil
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        searchEngineImageView.backgroundColor = isURLTextFieldCentered ? colors.layer3 : colors.layer2
        self.theme = theme
    }
}
