// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

protocol InAppBannerDelegate: AnyObject {
    func inAppBannerDidTapCTA(_ banner: InAppBannerView, action: InAppMessage.CTAAction?)
    func inAppBannerDidDismiss(_ banner: InAppBannerView)
}

final class InAppBannerView: UIView, ThemeApplicable {
    private struct UX {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let closeButtonSize: CGFloat = 16
    }

    weak var delegate: InAppBannerDelegate?
    let messageID: String
    private let message: InAppMessage

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
    }

    private lazy var ctaButton: LinkButton = .build { [weak self] button in
        button.addTarget(self, action: #selector(self?.ctaTapped), for: .touchUpInside)
    }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addTarget(self, action: #selector(self?.dismissTapped), for: .touchUpInside)
        button.accessibilityLabel = .AppMenu.AppMenuCloseAccessibilityLabel
    }

    private lazy var contentStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.spacing
    }

    private lazy var textStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = 4
    }

    init(message: InAppMessage) {
        self.messageID = message.id
        self.message = message
        super.init(frame: .zero)
        setupView()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        layer.cornerRadius = UX.cornerRadius
        clipsToBounds = true

        textStack.addArrangedSubview(titleLabel)

        if message.content.ctaLabel != nil {
            textStack.addArrangedSubview(ctaButton)
        }

        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(closeButton)

        addSubview(contentStack)

        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: UX.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.verticalPadding),
        ])
    }

    private func configure() {
        titleLabel.text = message.content.title ?? message.content.body

        if let ctaLabel = message.content.ctaLabel {
            let viewModel = LinkButtonViewModel(
                title: ctaLabel,
                a11yIdentifier: "InAppBanner.ctaButton"
            )
            ctaButton.configure(viewModel: viewModel)
        }
    }

    @objc private func ctaTapped() {
        delegate?.inAppBannerDidTapCTA(self, action: message.content.ctaAction)
    }

    @objc private func dismissTapped() {
        delegate?.inAppBannerDidDismiss(self)
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textSecondary
    }
}
