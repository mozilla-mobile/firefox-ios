// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import Shared

struct WallpaperSettingsHeaderViewModel {
    var theme: Theme
    var title: String
    var titleA11yIdentifier: String

    var description: String?
    var descriptionA11yIdentifier: String?

    var buttonTitle: String?
    var buttonA11yIdentifier: String?
    var buttonAction: (() -> Void)?
}

class WallpaperSettingsHeaderView: UICollectionReusableView, ReusableCell {
    private struct UX {
        static let stackViewSpacing: CGFloat = 4.0
        static let topBottomSpacing: CGFloat = 16.0
    }

    private var viewModel: WallpaperSettingsHeaderViewModel?

    // Views
    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.stackViewSpacing
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline, size: 12.0, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 12.0)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var learnMoreButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 12.0)
        button.contentHorizontalAlignment = .leading
        button.buttonEdgeSpacing = 0
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helper functions
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        learnMoreButton.setAttributedTitle(nil, for: .normal)

        contentStackView.removeArrangedView(descriptionLabel)
        descriptionLabel.removeFromSuperview()
        contentStackView.removeArrangedView(learnMoreButton)
        learnMoreButton.removeFromSuperview()
    }

    func configure(viewModel: WallpaperSettingsHeaderViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yIdentifier

        if let description = viewModel.description, let descriptionA11y = viewModel.descriptionA11yIdentifier {
            descriptionLabel.text = description
            descriptionLabel.accessibilityIdentifier = descriptionA11y
            contentStackView.addArrangedSubview(descriptionLabel)
        }

        if viewModel.buttonTitle != nil,
           let buttonA11y = viewModel.buttonA11yIdentifier,
           viewModel.buttonAction != nil {
            setButtonStyle(theme: viewModel.theme)
            learnMoreButton.addTarget(
                self,
                action: #selector((buttonTapped(_:))),
                for: .touchUpInside)
            learnMoreButton.accessibilityIdentifier = buttonA11y

            contentStackView.addArrangedSubview(learnMoreButton)

            // needed so the button sizes correctly
            setNeedsLayout()
            layoutIfNeeded()
        }

        applyTheme(theme: viewModel.theme)
    }

    @objc
    func buttonTapped(_ sender: Any) {
        viewModel?.buttonAction?()
    }
}

// MARK: - Private
private extension WallpaperSettingsHeaderView {
    func setupView() {
        contentStackView.addArrangedSubview(titleLabel)
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topBottomSpacing),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.topBottomSpacing),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

// MARK: - Themable
extension WallpaperSettingsHeaderView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        contentStackView.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        setButtonStyle(theme: theme)
    }

    private func setButtonStyle(theme: Theme) {
        let color = theme.colors.textPrimary
        learnMoreButton.setTitleColor(color, for: .normal)

        // in iOS 13 the title color set is not used for the attributed text color so we have to set it via attributes
        guard let buttonTitle = viewModel?.buttonTitle else { return }
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 12.0),
            .foregroundColor: color,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let attributeString = NSMutableAttributedString(string: buttonTitle,
                                                        attributes: labelAttributes)
        learnMoreButton.setAttributedTitle(attributeString, for: .normal)
    }
}
