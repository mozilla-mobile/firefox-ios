// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary
import Ecosia

/// A view representing an individual impact row, used in the New Tab Page to display environmental impact information.
final class NTPImpactRowView: UIView, ThemeApplicable {

    // MARK: - UX Constants

    /// Contains constants used for layout and sizing within the `NTPImpactRowView`.
    struct UX {
        static let horizontalSpacing: CGFloat = 8
        static let padding: CGFloat = 16
        static let imageHeight: CGFloat = 24
    }

    // MARK: - UI Elements

    /// Stack view to arrange title and subtitle labels vertically.
    private let titleAndSubtitleContainerView = UIStackView()

    /// Main horizontal stack view that arranges the image, title, subtitle, and action button.
    private let mainContainerView = UIStackView()

    /// A container view for the image.
    private lazy var imageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// The image view representing the icon in the row.
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        return image
    }()

    /// A label for displaying the title of the row.
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .ecosiaFamilyBrand(size: .ecosia.font._3l)
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    /// A label for displaying the subtitle of the row.
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    /// A resizable button for performing actions related to the row.
    private lazy var actionButton: ResizableButton = {
        let button = ResizableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.customFont = .preferredFont(forTextStyle: .footnote).semibold()
        button.titleLabel?.textAlignment = .right
        button.contentHorizontalAlignment = .right
        button.contentVerticalAlignment = .center
        button.buttonEdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()

    /// A divider view separating rows visually.
    private lazy var dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    /// Delegate for handling user interactions with the row.
    weak var delegate: NTPImpactCellDelegate?

    /// The information to display in this row, including title, subtitle, and button information.
    var info: ClimateImpactInfo {
        didSet {
            imageView.image = info.image
            imageView.accessibilityIdentifier = info.imageAccessibilityIdentifier
            titleLabel.text = info.title
            subtitleLabel.text = info.subtitle
            actionButton.isHidden = forceHideActionButton ? true : info.buttonTitle == nil
            actionButton.setTitle(info.buttonTitle, for: .normal)
        }
    }

    /// The current position of this row in the overall list (used for layout adjustments like masking).
    var position: (row: Int, totalCount: Int) = (0, 0) {
        didSet {
            let (row, count) = position
            dividerView.isHidden = row == (count - 1)
            setMaskedCornersUsingPosition(row: row, totalCount: count)
        }
    }

    /// Whether to forcefully hide the action button in this row.
    var forceHideActionButton: Bool = false {
        didSet {
            actionButton.isHidden = forceHideActionButton
        }
    }

    /// Optional background color for the row.
    var customBackgroundColor: UIColor?

    // MARK: - Initialization

    /// Initializes a new `NTPImpactRowView` with the provided `ClimateImpactInfo`.
    ///
    /// - Parameter info: The `ClimateImpactInfo` object containing the data to display in the row.
    init(info: ClimateImpactInfo) {
        self.info = info
        super.init(frame: .zero)
        defer {
            // Ensure info setup is completed after initialization
            self.info = info
        }
        setupView()
        setupConstraints()
    }

    /// Not supported, as `NTPImpactRowView` requires `ClimateImpactInfo` during initialization.
    required init?(coder: NSCoder) { nil }

    // MARK: - Setup Methods

    /// Configures and adds subviews to the view.
    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = .ecosia.borderRadius._l

        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.axis = .horizontal
        mainContainerView.alignment = .center
        mainContainerView.spacing = UX.horizontalSpacing
        mainContainerView.addArrangedSubview(imageContainer)
        imageContainer.addSubview(imageView)
        addSubview(mainContainerView)
        addSubview(dividerView)

        titleAndSubtitleContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleAndSubtitleContainerView.axis = .vertical
        titleAndSubtitleContainerView.alignment = .leading
        titleAndSubtitleContainerView.addArrangedSubview(titleLabel)
        titleAndSubtitleContainerView.addArrangedSubview(subtitleLabel)
        titleAndSubtitleContainerView.isAccessibilityElement = true
        titleAndSubtitleContainerView.shouldGroupAccessibilityChildren = true
        titleAndSubtitleContainerView.accessibilityLabel = info.accessibilityLabel
        titleAndSubtitleContainerView.accessibilityIdentifier = info.accessibilityIdentifier

        mainContainerView.addArrangedSubview(titleAndSubtitleContainerView)
        mainContainerView.addArrangedSubview(actionButton)
    }

    /// Sets up the layout constraints for the view's subviews.
    private func setupConstraints() {

        NSLayoutConstraint.activate([
            mainContainerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.padding),
            mainContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            mainContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding),
            mainContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.padding),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.padding),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            imageContainer.heightAnchor.constraint(equalToConstant: UX.imageHeight),
            imageContainer.widthAnchor.constraint(equalTo: imageContainer.heightAnchor),
            actionButton.topAnchor.constraint(equalTo: titleAndSubtitleContainerView.topAnchor),
            actionButton.bottomAnchor.constraint(equalTo: titleAndSubtitleContainerView.bottomAnchor),
            actionButton.widthAnchor.constraint(equalTo: mainContainerView.widthAnchor, multiplier: 1/3)
        ])

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
        ])
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = customBackgroundColor ?? theme.colors.ecosia.backgroundElevation1
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        subtitleLabel.textColor = theme.colors.ecosia.textSecondary
        actionButton.setTitleColor(theme.colors.ecosia.buttonBackgroundPrimary, for: .normal)
        dividerView.backgroundColor = theme.colors.ecosia.borderDecorative
    }

    // MARK: - Actions

    /// Handles the action button tap event, notifying the delegate.
    @objc private func buttonAction() {
        delegate?.impactCellButtonClickedWithInfo(info)
    }
}
