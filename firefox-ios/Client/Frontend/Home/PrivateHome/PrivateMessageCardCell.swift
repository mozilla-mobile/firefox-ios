// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary

// UI element used to describe details about private browsing on the private firefox homepage
class PrivateMessageCardCell: UIView, ThemeApplicable {
    typealias a11y = AccessibilityIdentifiers.PrivateMode.Homepage
    var privateBrowsingLinkTapped: (() -> Void)?

    struct PrivateMessageCard: Hashable {
        let title: String
        let body: String
        let link: String
    }

    enum UX {
        static let contentStackViewSpacing: CGFloat = 8
        static let contentStackPadding: CGFloat = 16
        static let labelFontSize: CGFloat = 15
        static let actionButtonInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }

    private lazy var cardContainer: ShadowCardView = .build()

    private lazy var mainView: UIView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
    }

    private lazy var headerLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .headline,
            size: UX.labelFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.title
        label.accessibilityTraits.insert(.header)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .body,
            size: UX.labelFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.body
    }

    private lazy var linkLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .body,
            size: UX.labelFontSize
        )
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.link
        label.accessibilityTraits.insert(.link)
        label.isUserInteractionEnabled = true
    }

    @objc
    func linkTapped(_ sender: UITapGestureRecognizer) {
        privateBrowsingLinkTapped?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: PrivateMessageCard, and theme: Theme) {
        headerLabel.text = item.title
        bodyLabel.text = item.body
        linkLabel.attributedText = getUnderlineText(for: item.link)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.linkTapped(_:)))
        linkLabel.addGestureRecognizer(tapGesture)

        let cardModel = ShadowCardViewModel(view: mainView, a11yId: a11y.card)
        cardContainer.configure(cardModel)
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
    }

    private func setupLayout() {
        addSubviews(cardContainer, mainView)
        mainView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerLabel)
        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.addArrangedSubview(linkLabel)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: cardContainer.topAnchor,
                                                  constant: UX.contentStackPadding),
            contentStackView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor,
                                                     constant: -UX.contentStackPadding),
            contentStackView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor,
                                                      constant: UX.contentStackPadding),
            contentStackView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor,
                                                       constant: -UX.contentStackPadding),
        ])
    }

    private func getUnderlineText(for text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
}
