// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary

final class NativeErrorPageAdvancedView: UIView, ThemeApplicable {
    private enum UX {
        static let contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 20
        static let contentStackSpacing: CGFloat = 20
        static let headerStackSpacing: CGFloat = 4
        static let headerTextStackSpacing: CGFloat = 2
        static let titleStackSpacing: CGFloat = 4
        static let detailsStackSpacing: CGFloat = 10
        static let footerStackSpacing: CGFloat = 20
        static let buttonsStackSpacing: CGFloat = 12
        static let errorInfoStackSpacing: CGFloat = 4
        static let iconSize: CGFloat = 16
        static let chevronBackgroundSize: CGFloat = 20
        static let bulletWidth: CGFloat = 20
        static let buttonInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        static let dividerHeight: CGFloat = 0.5
    }

    var onLearnMore: (() -> Void)?
    var onViewCertificate: (() -> Void)?
    var onProceed: (() -> Void)?

    private var isExpanded = false
    private var detailLabels: [UILabel] = []

    // MARK: - Views

    private let contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackSpacing
    }

    private let headerStackView: UIStackView = .build { stackView in
        stackView.alignment = .center
        stackView.spacing = UX.headerStackSpacing
        stackView.isAccessibilityElement = true
        stackView.accessibilityTraits = .button
        stackView.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedSectionHeader
    }

    private let headerTextStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.headerTextStackSpacing
        stackView.alignment = .leading
    }

    private let titleStackView: UIStackView = .build { stackView in
        stackView.spacing = UX.titleStackSpacing
        stackView.alignment = .center
    }

    private let iconView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.warningFill)?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = .NativeErrorPage.Security.Advanced.TitleLabel
    }

    private let summaryLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private let chevronBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = UX.chevronBackgroundSize / 2
    }

    private let chevronView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private let topDivider: UIView = .build()
    private let bottomDivider: UIView = .build()

    private let detailsStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.detailsStackSpacing
    }

    private let learnMoreButton: LinkButton = .build()

    private let footerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.footerStackSpacing
    }

    private let buttonsStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.buttonsStackSpacing
    }

    private lazy var viewCertificateButton = makeButton(title: .NativeErrorPage.Security.Advanced.ViewCertificateButton)
    private lazy var proceedButton = makeButton(title: nil)

    private let errorInfoStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.errorInfoStackSpacing
    }

    private let errorCodeLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption2.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedErrorCodeLabel
    }

    private let dateLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption2.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedDateLabel
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = UX.cornerRadius
        setupLayout()
        setupButtons()
        updateExpanded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        setupStackViews()
        addSubview(contentStackView)
        setupConstraints()
    }

    // MARK: - Content

    func configure(with advanced: RefactoredNativeErrorPageModel.Advanced, errorCode: Int) {
        updateHeader(summary: advanced.summary)
        updateDetails(advanced.details)
        updateCertificateButtons(proceedTitle: advanced.proceedTitle)
        updateErrorInfo(errorCode: errorCode)
    }

    // MARK: - Actions

    @objc
    private func toggleExpanded() {
        isExpanded.toggle()
        updateExpanded()
    }

    // MARK: - Theme

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layerSurfaceLow
        iconView.tintColor = theme.colors.faviconLetterColorSet.iconAccentOrange4
        titleLabel.textColor = theme.colors.textPrimary
        summaryLabel.textColor = theme.colors.textSecondary
        chevronBackgroundView.backgroundColor = theme.colors.actionSecondary
        chevronView.tintColor = theme.colors.iconSecondary
        [topDivider, bottomDivider].forEach { $0.backgroundColor = theme.colors.borderPrimary }

        detailLabels.forEach { $0.textColor = theme.colors.textSecondary }
        learnMoreButton.applyTheme(theme: theme)

        viewCertificateButton.configuration?.baseBackgroundColor = theme.colors.actionSecondary
        viewCertificateButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        proceedButton.configuration?.baseBackgroundColor = theme.colors.layerCritical
        proceedButton.configuration?.baseForegroundColor = theme.colors.textCritical

        errorCodeLabel.textColor = theme.colors.textPrimary
        dateLabel.textColor = theme.colors.textSecondary
    }

    // MARK: - Helpers

    private func setupStackViews() {
        [iconView, titleLabel].forEach(titleStackView.addArrangedSubview)
        [titleStackView, summaryLabel].forEach(headerTextStackView.addArrangedSubview)
        chevronBackgroundView.addSubview(chevronView)
        [headerTextStackView, chevronBackgroundView].forEach(headerStackView.addArrangedSubview)

        [viewCertificateButton, proceedButton].forEach(buttonsStackView.addArrangedSubview)
        [errorCodeLabel, dateLabel].forEach(errorInfoStackView.addArrangedSubview)
        [buttonsStackView, errorInfoStackView].forEach(footerStackView.addArrangedSubview)

        [headerStackView, topDivider, detailsStackView, bottomDivider, footerStackView]
            .forEach(contentStackView.addArrangedSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentInsets.top),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentInsets.leading),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentInsets.trailing),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentInsets.bottom),

            iconView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: UX.iconSize),

            chevronBackgroundView.widthAnchor.constraint(equalToConstant: UX.chevronBackgroundSize),
            chevronBackgroundView.heightAnchor.constraint(equalToConstant: UX.chevronBackgroundSize),
            chevronView.centerXAnchor.constraint(equalTo: chevronBackgroundView.centerXAnchor),
            chevronView.centerYAnchor.constraint(equalTo: chevronBackgroundView.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: UX.iconSize),
            chevronView.heightAnchor.constraint(equalToConstant: UX.iconSize),

            topDivider.heightAnchor.constraint(equalToConstant: UX.dividerHeight),
            bottomDivider.heightAnchor.constraint(equalToConstant: UX.dividerHeight),
        ])
    }

    private func setupButtons() {
        headerStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleExpanded)))

        learnMoreButton.configure(viewModel: LinkButtonViewModel(
            title: .NativeErrorPage.Security.Advanced.LearnMoreLink,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.learnMoreLink,
            font: FXFontStyles.Regular.footnote.scaledFont(),
            contentInsets: .zero
        ))
        viewCertificateButton.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.viewCertificateLink
        proceedButton.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.proceedButton

        learnMoreButton.addAction(UIAction { [weak self] _ in self?.onLearnMore?() }, for: .touchUpInside)
        viewCertificateButton.addAction(UIAction { [weak self] _ in self?.onViewCertificate?() }, for: .touchUpInside)
        proceedButton.addAction(UIAction { [weak self] _ in self?.onProceed?() }, for: .touchUpInside)
    }

    private func updateHeader(summary: String) {
        summaryLabel.text = summary
        headerStackView.accessibilityLabel = "\(String.NativeErrorPage.Security.Advanced.TitleLabel), \(summary)"
    }

    private func updateDetails(_ details: [String]) {
        detailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detailLabels = []

        for detail in details {
            let label = makeLabel()
            label.text = detail
            label.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedDetailLabel
            detailLabels.append(label)
            detailsStackView.addArrangedSubview(makeBulletRow(bullet: "•", content: label))
        }
        detailsStackView.addArrangedSubview(makeBulletRow(bullet: nil, content: learnMoreButton))
    }

    private func updateCertificateButtons(proceedTitle: String?) {
        proceedButton.configuration?.title = proceedTitle
        proceedButton.isHidden = proceedTitle == nil
        viewCertificateButton.isHidden = proceedTitle == nil
    }

    private func updateErrorInfo(errorCode: Int) {
        errorCodeLabel.text = String(format: .NativeErrorPage.ErrorCodeLabel, String(errorCode))

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        dateLabel.text = formatter.string(from: Date())
    }

    private func updateExpanded() {
        [topDivider, detailsStackView, bottomDivider, footerStackView].forEach { $0.isHidden = !isExpanded }
        chevronView.image = UIImage(named: isExpanded ? StandardImageIdentifiers.Large.chevronDown
                                                      : StandardImageIdentifiers.Large.chevronRight)?
            .imageFlippedForRightToLeftLayoutDirection()
    }

    private func makeButton(title: String?) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .capsule
        configuration.contentInsets = UX.buttonInsets
        configuration.title = title
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Regular.subheadline.scaledFont()
            return outgoing
        }
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func makeLabel() -> UILabel {
        let label: UILabel = .build { label in
            label.font = FXFontStyles.Regular.footnote.scaledFont()
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
        }
        return label
    }

    private func makeBulletRow(bullet: String?, content: UIView) -> UIStackView {
        let bulletLabel = makeLabel()
        bulletLabel.text = bullet
        detailLabels.append(bulletLabel)

        let row = UIStackView(arrangedSubviews: [bulletLabel, content])
        row.alignment = .firstBaseline
        bulletLabel.widthAnchor.constraint(equalToConstant: UX.bulletWidth).isActive = true
        return row
    }
}
