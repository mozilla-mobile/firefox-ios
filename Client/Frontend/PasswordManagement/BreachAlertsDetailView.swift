// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class BreachAlertsDetailView: UIView, ThemeApplicable {
    private struct UX {
        static let horizontalMargin: CGFloat = 14
        static let shadowRadius: CGFloat = 8
        static let shadowOpacity: Float = 0.6
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    private var breachLink = String()
    private let titleIconSize: CGFloat = 24
    private lazy var titleIconContainerSize: CGFloat = {
        return titleIconSize + UX.horizontalMargin * 2
    }()

    lazy var titleIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: ImageIdentifiers.breachedWebsite)?
            .withRenderingMode(.alwaysTemplate))
        imageView.accessibilityTraits = .image
        imageView.accessibilityLabel = "Breach Alert Icon"
        return imageView
    }()

    lazy var titleIconContainer: UIView = {
        let container = UIView()
        container.addSubview(titleIcon)
        titleIcon.snp.makeConstraints { make in
            make.width.height.equalTo(titleIconSize)
            make.center.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.width.height.equalTo(titleIconContainerSize)
        }
        return container
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .headline,
                                                                size: 19)
        label.text = .BreachAlertsTitle
        label.sizeToFit()
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = .BreachAlertsTitle
        return label
    }()

    lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = LegacyDynamicFontHelper.defaultHelper.DeviceFontSmallBold
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button
        button.accessibilityLabel = .BreachAlertsLearnMore
        return button
    }()

    lazy var titleStack: UIStackView = {
        let container = UIStackView(arrangedSubviews: [titleIconContainer, titleLabel, learnMoreButton])
        container.axis = .horizontal
        return container
    }()

    lazy var breachDateLabel: UILabel = {
        let label = UILabel()
        label.text = .BreachAlertsBreachDate
        label.numberOfLines = 0
        label.font = LegacyDynamicFontHelper.defaultHelper.DeviceFontSmallBold
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = .BreachAlertsBreachDate
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = .BreachAlertsDescription
        label.numberOfLines = 0
        label.font = LegacyDynamicFontHelper.defaultHelper.DeviceFontSmall
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        return label
    }()

    lazy var goToButton: UILabel = {
        let button = UILabel()
        button.font = LegacyDynamicFontHelper.defaultHelper.DeviceFontSmallBold
        button.numberOfLines = 0
        button.isUserInteractionEnabled = true
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button
        button.accessibilityLabel = .BreachAlertsLink
        return button
    }()

    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [breachDateLabel, descriptionLabel, goToButton])
        stack.distribution = .fill
        stack.axis = .vertical
        stack.setCustomSpacing(8.0, after: descriptionLabel)
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleStack, infoStack])
        stack.axis = .vertical
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayerAppearance()

        self.isAccessibilityElement = false
        self.accessibilityElements = [titleLabel, learnMoreButton, breachDateLabel, descriptionLabel, goToButton]

        self.addSubview(contentStack)
        self.configureView(for: self.traitCollection)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        titleStack.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        infoStack.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(titleIconContainerSize)
            make.trailing.equalToSuperview()
        }
        contentStack.snp.remakeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(UX.horizontalMargin)
            make.leading.top.equalToSuperview()
        }
        self.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
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
        self.breachDateLabel.text! += " \(dateFormatter.string(from: date))."
        breachLink = .BreachAlertsLink + " \(breach.domain)"
        self.goToButton.sizeToFit()
        self.layoutIfNeeded()

        self.goToButton.accessibilityValue = breach.domain
        self.breachDateLabel.accessibilityValue = "\(dateFormatter.string(from: date))."
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
            self.titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(self.titleIconSize)
            }
            self.learnMoreButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(self.titleIconSize)
            }
        } else {
            self.titleStack.axis = .horizontal
            self.titleStack.alignment = .leading
            self.titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
            }
            self.learnMoreButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
            }
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        layer.shadowColor = theme.colors.shadowDefault.cgColor
        backgroundColor = theme.colors.layer2
        titleIcon.tintColor = theme.colors.iconWarning
        titleLabel.textColor = theme.colors.textWarning
        breachDateLabel.textColor = theme.colors.textWarning
        descriptionLabel.textColor = theme.colors.textWarning
        goToButton.attributedText = getAttributedText(for: breachLink,
                                                      with: theme.colors.textWarning)
        learnMoreButton.setAttributedTitle(getAttributedText(for: .BreachAlertsLearnMore,
                                                             with: theme.colors.textWarning),
                                           for: .normal)
    }
}
