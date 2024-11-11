// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// A view which contains a search engine icon and a drop down arrow. Supports tapping actions which call the appropriate
/// method on the `LocationViewDelegate`.
final class DropDownSearchEngineView: UIView, SearchEngineView, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let cornerRadius: CGFloat = 4
        static let dropDownMargin: CGFloat = 4
        static let imageViewMargin: CGFloat = 2
        static let searchEngineImageSize = CGSize(width: 24, height: 24)
        static let chevronImageSize = CGSize(width: 8, height: 8)
    }

    private weak var delegate: LocationViewDelegate?

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.isAccessibilityElement = true
    }

    private lazy var arrowImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: StandardImageIdentifiers.ExtraSmall.chevronDown)?.withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        searchEngineImageView.image = state.searchEngineImage
        configureA11y(state)
        self.delegate = delegate
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubviews(searchEngineImageView, arrowImageView)

        NSLayoutConstraint.activate([
            searchEngineImageView.widthAnchor.constraint(equalToConstant: UX.searchEngineImageSize.width),
            searchEngineImageView.heightAnchor.constraint(equalToConstant: UX.searchEngineImageSize.height),
            searchEngineImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.imageViewMargin),
            searchEngineImageView.topAnchor.constraint(equalTo: topAnchor, constant: UX.imageViewMargin),
            searchEngineImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.imageViewMargin),

            arrowImageView.widthAnchor.constraint(equalToConstant: UX.chevronImageSize.width),
            arrowImageView.heightAnchor.constraint(equalToConstant: UX.chevronImageSize.height),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.leadingAnchor.constraint(
                equalTo: searchEngineImageView.trailingAnchor,
                constant: UX.dropDownMargin
            ),
            arrowImageView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -UX.dropDownMargin
            ),
        ])
    }

    private func setupView() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapSearchEngine)))
        layer.cornerRadius = UX.cornerRadius
    }

    // MARK: - Accessibility

    private func configureA11y(_ state: LocationViewState) {
         searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
         searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel
         searchEngineImageView.largeContentTitle = state.searchEngineImageViewA11yLabel
         searchEngineImageView.largeContentImage = nil
    }

    // MARK: - Selectors

    @objc
    private func didTapSearchEngine() {
        delegate?.locationViewDidTapSearchEngine(self)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        let colors = theme.colors
        backgroundColor = colors.layer2
        searchEngineImageView.backgroundColor = colors.layer2
        arrowImageView.tintColor = colors.iconPrimary
    }
}
