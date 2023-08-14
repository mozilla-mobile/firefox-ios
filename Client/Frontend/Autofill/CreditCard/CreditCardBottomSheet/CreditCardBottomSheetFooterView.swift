// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class CreditCardBottomSheetFooterView: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let manageCardsButtonFontSize: CGFloat = 16
        static let manageCardsButtonLeadingSpace: CGFloat = 0
        static let manageCardsButtonTopSpace: CGFloat = 24
        static let manageCardsButtonBottomSpace: CGFloat = 24
        static let titleVerticalPadding: CGFloat = 6
        static let titleVerticalLongPadding: CGFloat = 20
    }

    public lazy var manageCardsButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .callout,
            size: UX.manageCardsButtonFontSize)
        button.setTitle(.CreditCard.UpdateCreditCard.ManageCardsButtonTitle, for: .normal)
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.RememberCreditCard.yesButton
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(manageCardsButton)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.layer1
        manageCardsButton.setTitleColor(theme.colors.textAccent, for: .normal)
    }

    private func setupView() {
        NSLayoutConstraint.activate([
            manageCardsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                       constant: UX.manageCardsButtonLeadingSpace),
            manageCardsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                        constant: -UX.manageCardsButtonLeadingSpace),
            manageCardsButton.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                   constant: UX.manageCardsButtonTopSpace),
            manageCardsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                      constant: -UX.manageCardsButtonBottomSpace)
        ])
    }
}
