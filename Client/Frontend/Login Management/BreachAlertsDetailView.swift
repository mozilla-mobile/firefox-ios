/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class BreachAlertsDetailView: UIView {

    private let textColor = UIColor.white
    private let titleIconSize: CGFloat = 24
    private lazy var titleIconContainerSize: CGFloat = {
        return titleIconSize + LoginTableViewCellUX.HorizontalMargin * 2
    }()

    lazy var titleIcon: UIImageView = {
        let imageView = UIImageView(image: BreachAlertsManager.icon)
        imageView.tintColor = textColor
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
        label.font = DynamicFontHelper.defaultHelper.DeviceFontLargeBold
        label.textColor = textColor
        label.text = Strings.BreachAlertsTitle
        label.sizeToFit()
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = Strings.BreachAlertsTitle
        return label
    }()

    lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attributedText = NSMutableAttributedString(string: Strings.BreachAlertsLearnMore, attributes: attributes)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        button.setAttributedTitle(attributedText, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.tintColor = .white
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button
        button.accessibilityLabel = Strings.BreachAlertsLearnMore
        return button
    }()

    lazy var titleStack: UIStackView = {
        let container = UIStackView(arrangedSubviews: [titleIconContainer, titleLabel, learnMoreButton])
        container.axis = .horizontal
        return container
    }()

    lazy var breachDateLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsBreachDate
        label.textColor = textColor
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.accessibilityLabel = Strings.BreachAlertsBreachDate
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsDescription
        label.numberOfLines = 0
        label.textColor = textColor
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmall
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        return label
    }()

    lazy var goToButton: UILabel = {
        let button = UILabel()
        button.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        button.textColor = textColor
        button.numberOfLines = 0
        button.isUserInteractionEnabled = true
        button.text = Strings.BreachAlertsLink
        button.isAccessibilityElement = true
        button.accessibilityTraits = .button
        button.accessibilityLabel = Strings.BreachAlertsLink
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

        self.backgroundColor = BreachAlertsManager.lightMode
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true

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
            make.bottom.trailing.equalToSuperview().inset(LoginTableViewCellUX.HorizontalMargin)
            make.leading.top.equalToSuperview()
        }
        self.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    // Populate the view with information from a BreachRecord.
    public func setup(_ breach: BreachRecord) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: breach.breachDate) else { return }
        dateFormatter.dateStyle = .medium
        self.breachDateLabel.text! += " \(dateFormatter.string(from: date))."
        let goToText = Strings.BreachAlertsLink + " \(breach.domain)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attributedText = NSMutableAttributedString(string: goToText, attributes: attributes)
        self.goToButton.attributedText = attributedText
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
}
