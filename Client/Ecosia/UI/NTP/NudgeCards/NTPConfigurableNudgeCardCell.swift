// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Common

/// Reusable Nudge Card Cell that can be configured with any view model.
class NTPConfigurableNudgeCardCell: UICollectionViewCell, Themeable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let cornerRadius: CGFloat = 10
        static let closeButtonWidthHeight: CGFloat = 48
        static let insetMargin: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let mainContainerSpacing: CGFloat = 4
        static let buttonAdditionalSpacing: CGFloat = 8
        static let imageWidthHeight: CGFloat = 48
    }

    // MARK: - UI Components

    private let mainContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.cornerRadius = UX.cornerRadius
        stackView.spacing = UX.mainContainerSpacing
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: UX.insetMargin,
                                                   leading: UX.insetMargin,
                                                   bottom: UX.insetMargin,
                                                   trailing: UX.insetMargin)
        stackView.spacing = UX.textSpacing
        return stackView
    }()

    private let labelsAndActionButtonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = UX.textSpacing
        return stackView
    }()

    private let closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(.init(named: "closeButtonStandard"), for: .normal)
        button.contentMode = .top
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline).bold()
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.setInsets(forContentPadding: .init(top: UX.buttonAdditionalSpacing, left: 0, bottom: 0, right: 0), imageTitlePadding: 0)
        return button
    }()

    // MARK: - Properties

    private var viewModel: NTPConfigurableNudgeCardCellViewModel?

    // MARK: - Delegate

    weak var delegate: NTPConfigurableNudgeCardCellDelegate?

    // MARK: - Themeable Properties

    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(mainContainerStackView)

        labelsAndActionButtonStackView.addArrangedSubview(titleLabel)
        labelsAndActionButtonStackView.addArrangedSubview(descriptionLabel)
        labelsAndActionButtonStackView.addArrangedSubview(actionButton)

        mainContainerStackView.addArrangedSubview(imageView)
        mainContainerStackView.addArrangedSubview(labelsAndActionButtonStackView)
        mainContainerStackView.addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            mainContainerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainContainerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainContainerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            imageView.heightAnchor.constraint(equalToConstant: UX.imageWidthHeight),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
        ])

        applyTheme()
        listenForThemeChange(contentView)
    }

    // MARK: - Configuration Method

    /// Configures the Nudge Card Cell using the ViewModel.
    func configure(with viewModel: NTPConfigurableNudgeCardCellViewModel) {

        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        actionButton.setTitle(viewModel.buttonText, for: .normal)

        if let image = viewModel.image {
            imageView.image = image
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }

        closeButton.isHidden = !viewModel.showsCloseButton
        self.viewModel = viewModel
        delegate = viewModel.delegate

        // Apply accessibility updates
        configureAccessibility()
    }

    private func configureAccessibility() {
        // Set accessibility labels and traits based on the ViewModel
        titleLabel.accessibilityLabel = viewModel?.title
        descriptionLabel.accessibilityLabel = viewModel?.description
        actionButton.accessibilityLabel = viewModel?.buttonText
        closeButton.accessibilityLabel = .localized(.configurableNudgeCardCloseButtonAccessibilityLabel)
    }

    // MARK: - Theming
    @objc func applyTheme() {
        // Apply theming based on the provided theme from the ViewModel
        mainContainerStackView.backgroundColor = .legacyTheme.ecosia.secondaryBackground
        closeButton.tintColor = .legacyTheme.ecosia.decorativeIcon
        titleLabel.textColor = .legacyTheme.ecosia.primaryText
        descriptionLabel.textColor = .legacyTheme.ecosia.secondaryText
        actionButton.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
    }

    @objc private func closeAction() {
        guard let cardSectionType = viewModel?.cardSectionType else { return }
        delegate?.nudgeCardRequestToDimiss(for: cardSectionType)
    }

    @objc private func actionButtonTapped() {
        guard let cardSectionType = viewModel?.cardSectionType else { return }
        delegate?.nudgeCardRequestToPerformAction(for: cardSectionType)
    }
}
