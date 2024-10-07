// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// TODO FXIOS-10193 This file is a placeholder stub for FXIOS-10193 customization
/// A view which contains a search engine icon and a drop down arrow. Supports tapping actions which call the appropriate
/// method on the `LocationViewDelegate`.
final class DropDownSearchEngineView: UIView, SearchEngineView, ThemeApplicable {
    // MARK: - Properties
    private enum UX {
        static let cornerRadius: CGFloat = 4
        static let dropDownMargin: CGFloat = 4
        static let imageViewMargin: CGFloat = 2
        static let imageViewSize = CGSize(width: 24, height: 24)
        static let downArrowSize = CGSize(width: 8, height: 8)
    }

    private weak var delegate: LocationViewDelegate? // TODO FXIOS-10193 Notify delegate on tap (add selector)

    private lazy var searchEngineImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.isAccessibilityElement = true
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ state: LocationViewState, delegate: LocationViewDelegate) {
        // TODO FXIOS-10193 Load the image into the imageView
        searchEngineImageView.backgroundColor = UIColor.red // Placeholder
        configureA11y(state)
        self.delegate = delegate
    }

    // MARK: - Layout

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = true
        addSubviews(searchEngineImageView)

        // TODO FXIOS-10193 Add subviews to create the new button with the drop-down arrow
        //
        //
        //

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

    private func configureA11y(_ state: LocationViewState) {
        // TODO FXIOS-10193 Enforce correct accessibility identifiers after finalizing the UI for DropDownSearchEngineView
        // e.g.) Old code, may need updating:
        // searchEngineImageView.accessibilityIdentifier = state.searchEngineImageViewA11yId
        // searchEngineImageView.accessibilityLabel = state.searchEngineImageViewA11yLabel
        // searchEngineImageView.largeContentTitle = state.searchEngineImageViewA11yLabel
        // searchEngineImageView.largeContentImage = nil
    }

    // MARK: - Selectors

    // TODO FXIOS-10193 Add selector action method to bubble up tap of this view to the delegate
    // TODO FXIOS-10191 Actual selector implementation to come later.

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        // TODO FXIOS-10193 Apply theme to new subviews
        // e.g.)  Old code, may need updating:
        // let colors = theme.colors
        // searchEngineImageView.backgroundColor = colors.layer2
    }
}
