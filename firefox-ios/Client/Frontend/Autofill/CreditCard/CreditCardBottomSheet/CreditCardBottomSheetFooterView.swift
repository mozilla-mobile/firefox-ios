// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

class CreditCardBottomSheetFooterView: UITableViewHeaderFooterView,
                                       ReusableCell,
                                       ThemeApplicable {
    private struct UX {
        static let topBottomMargin: CGFloat = 24
        static let layoutPriority: Float = 999
    }

    private let containerView: UIView = .build()
    public lazy var manageCardsButton: LinkButton  = .build { button in }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        setupButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.layer1
        manageCardsButton.applyTheme(theme: theme)
    }

    private func setupView() {
        contentView.addSubview(containerView)
        containerView.addSubview(manageCardsButton)

        let bottomConstraint = containerView.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -UX.topBottomMargin
        )
        bottomConstraint.priority = UILayoutPriority(UX.layoutPriority)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.topBottomMargin),
            bottomConstraint,
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            manageCardsButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            manageCardsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            manageCardsButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            manageCardsButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    private func setupButton() {
        let buttonViewModel = LinkButtonViewModel(
            title: .CreditCard.UpdateCreditCard.ManageCardsButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.RememberCreditCard.manageCardsButton,
            font: FXFontStyles.Regular.callout.scaledFont(),
            contentHorizontalAlignment: .left
        )
        manageCardsButton.configure(viewModel: buttonViewModel)
    }
}
