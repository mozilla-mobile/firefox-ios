// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class BreachAlertsDetailView: UIView, ThemeApplicable {
    private struct UX {
        static let verticalSpacing: CGFloat = 8.0
        static let horizontalMargin: CGFloat = 14
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.6
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let titleIconSize: CGFloat = 24
    }

    private var breachLink = String()

    private lazy var titleIconContainerSize: CGFloat = {
        return UX.titleIconSize + UX.horizontalMargin * 2
    }()

    private lazy var titleIcon: UIImageView = .build { imageView in
        imageView.accessibilityTraits = .image
        imageView.accessibilityLabel = "Breach Alert Icon"
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.warningFill)?.withRenderingMode(.alwaysTemplate)
    }

    private lazy var titleIconContainer: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.text = .BreachAlertsTitle
        label.sizeToFit()
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = .BreachAlertsTitle
    }

    private lazy var learnMoreButton: UIButton = .build { button in
        button.titleLabel?.font  = FXFontStyles.Bold.callout.scaledFont()
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button
        button.accessibilityLabel = .BreachAlertsLearnMore
        button.addTarget(self, action: #selector(self.didTapBreachLearnMore), for: .touchUpInside)
    }

    private lazy var breachDateLabel: UILabel = .build { label in
        label.text = .BreachAlertsBreachDate
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = .BreachAlertsBreachDate
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.text = .BreachAlertsDescription
        label.numberOfLines = 0
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
    }

    private lazy var goToLabel: UILabel = .build { label in
        let breachLinkGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapBreachLink))
        label.addGestureRecognizer(breachLinkGesture)
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.isAccessibilityElement = true
        label.accessibilityTraits = .button
        label.accessibilityLabel = .BreachAlertsLink
    }

    private lazy var titleStack: UIStackView = .build()

    private lazy var infoStack: UIStackView = .build { stack in
        stack.distribution = .fill
        stack.axis = .vertical
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .vertical
    }

    var onTapLearnMore: (() -> Void)?
    var onTapBreachLink: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayerAppearance()
        setupUI()
        setupLayout()

        isAccessibilityElement = false
        accessibilityElements = [titleLabel, learnMoreButton, breachDateLabel, descriptionLabel, goToLabel]

        configureView(for: traitCollection)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        titleIconContainer.addSubview(titleIcon)
        [titleIconContainer, titleLabel, learnMoreButton].forEach(titleStack.addArrangedSubview)

        [breachDateLabel, descriptionLabel, goToLabel].forEach(infoStack.addArrangedSubview)
        infoStack.setCustomSpacing(UX.verticalSpacing, after: self.descriptionLabel)

        [titleStack, infoStack].forEach(contentStack.addArrangedSubview)
        addSubview(contentStack)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            titleIcon.widthAnchor.constraint(equalToConstant: UX.titleIconSize),
            titleIcon.heightAnchor.constraint(equalToConstant: UX.titleIconSize),
            titleIcon.centerXAnchor.constraint(equalTo: titleIconContainer.centerXAnchor),
            titleIcon.centerYAnchor.constraint(equalTo: titleIconContainer.centerYAnchor),

            titleIconContainer.widthAnchor.constraint(equalToConstant: titleIconContainerSize),
            titleIconContainer.heightAnchor.constraint(equalToConstant: titleIconContainerSize),

            titleStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            titleStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),

            infoStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor, constant: titleIconContainerSize),
            infoStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor),

            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.horizontalMargin),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalMargin),
            contentStack.topAnchor.constraint(equalTo: topAnchor)
        ])
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    @objc
    private func didTapBreachLearnMore() {
        onTapLearnMore?()
    }

    @objc
    private func didTapBreachLink() {
        onTapBreachLink?()
    }

    private func configureLayerAppearance() {
        layer.cornerRadius = 5
        layer.masksToBounds = false

        layer.shadowOpacity = UX.shadowOpacity
        layer.shadowOffset = UX.shadowOffset
        layer.shadowRadius = UX.shadowRadius
    }

    private func getAttributedText(for text: String, with color: UIColor) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }

    // Populate the view with information from a BreachRecord.
    public func setup(_ breach: BreachRecord) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: breach.breachDate) else { return }
        dateFormatter.dateStyle = .medium
        breachDateLabel.text! += " \(dateFormatter.string(from: date))."
        breachLink = .BreachAlertsLink + " \(breach.domain)"
        goToLabel.sizeToFit()
        layoutIfNeeded()

        goToLabel.accessibilityValue = breach.domain
        breachDateLabel.accessibilityValue = "\(dateFormatter.string(from: date))."
    }

    // MARK: - Dynamic Type Support
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != self.traitCollection.preferredContentSizeCategory {
            configureView(for: self.traitCollection)
        }
    }

    // If large fonts are enabled, set the title stack vertically.
    // Else, set the title stack horizontally.
    private func configureView(for traitCollection: UITraitCollection) {
        let contentSize = traitCollection.preferredContentSizeCategory
        if contentSize.isAccessibilityCategory {
            self.titleStack.axis = .vertical
            self.titleStack.alignment = .leading

            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: titleStack.leadingAnchor, constant: UX.titleIconSize),
                learnMoreButton.leadingAnchor.constraint(equalTo: titleStack.leadingAnchor, constant: UX.titleIconSize)
            ])
        } else {
            self.titleStack.axis = .horizontal
            self.titleStack.alignment = .leading

            NSLayoutConstraint.activate([
                titleLabel.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor),
                learnMoreButton.centerYAnchor.constraint(equalTo: titleStack.centerYAnchor)
            ])
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        layer.shadowColor = colors.shadowDefault.cgColor
        backgroundColor = colors.layer2
        titleIcon.tintColor = colors.iconCritical
        titleLabel.textColor = colors.textCritical
        breachDateLabel.textColor = colors.textCritical
        descriptionLabel.textColor = colors.textCritical
        goToLabel.attributedText = getAttributedText(
            for: breachLink,
            with: colors.textCritical
        )
        learnMoreButton.setAttributedTitle(
            getAttributedText(
                for: .BreachAlertsLearnMore,
                with: colors.textCritical
            ),
            for: .normal
        )
    }
}
