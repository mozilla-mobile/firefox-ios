// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit


final class WorldCupErrorView: UIView, ThemeApplicable {
    private struct UX {
        static let horizontalPadding: CGFloat = 16
        static let titleLabelLeadingPadding: CGFloat = 12.0
        static let refreshButtonTopPadding: CGFloat = 16.0
        static let imageSize = CGSize(width: 36, height: 40)
        static let imageName = "kitError"

        static let refreshButtonContentInsets = NSDirectionalEdgeInsets(
            top: 4,
            leading: 10,
            bottom: 4,
            trailing: 10
        )
        static let refreshButtonImagePadding: CGFloat = 3
    }

    private let windowUUID: WindowUUID

    // MARK: - UI

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: UX.imageName)
        imageView.isAccessibilityElement = false
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.text = .WorldCup.HomepageWidget.MatchUnavailableLabel
    }

    private lazy var refreshButton: UIButton = {
        var config = UIButton.Configuration.borderless()
        config.title = .WorldCup.HomepageWidget.MatchUnavailableRefreshButtonLabel
        config.image = UIImage(named: StandardImageIdentifiers.Medium.arrowClockwise)?.withRenderingMode(.alwaysTemplate)
        config.imagePadding = UX.refreshButtonImagePadding
        config.contentInsets = UX.refreshButtonContentInsets
        config.titleLineBreakMode = .byWordWrapping
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var container = incoming
            container.font = FXFontStyles.Regular.footnote.scaledFont()
            return container
        }
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityLabel = .WorldCup.HomepageWidget.MatchUnavailableRefreshButtonLabel
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.handleRefreshTap()
        }), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        addSubviews(imageView, titleLabel, refreshButton)

        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),
            imageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: UX.imageSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.imageSize.height),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: UX.titleLabelLeadingPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
            
            refreshButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.refreshButtonTopPadding),
            refreshButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            refreshButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: UX.horizontalPadding),
            refreshButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -UX.horizontalPadding),
        ])
    }
    
    func configure(state: WorldCupSectionState) {
        guard let error = state.apiError else { return }
        switch error {
        case .network(_):
            titleLabel.text = .WorldCup.HomepageWidget.OfflineLabel
        case .other(_, _):
            titleLabel.text = .WorldCup.HomepageWidget.MatchUnavailableLabel
        }
    }

    private func handleRefreshTap() {
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupActionType.retryMatchesFetch
            )
        )
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        refreshButton.tintColor = theme.colors.textPrimary
    }
}
