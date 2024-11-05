// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

protocol TextFieldTableViewCellDelegate: AnyObject {
    func textFieldTableViewCell(_ textFieldTableViewCell: TextFieldTableViewCell, didChangeText text: String)
}

class TextFieldTableViewCell: UITableViewCell, ThemeApplicable {
    private struct UX {
        static let HorizontalMargin: CGFloat = 16
        static let VerticalMargin: CGFloat = 10
        static let TitleLabelFont = UIFont.systemFont(ofSize: 12)
        static let TextFieldFont = UIFont.systemFont(ofSize: 16)
    }

    private lazy var titleLabel: UILabel = .build()
    private lazy var textField: UITextField = .build()

    weak var delegate: TextFieldTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubviews(titleLabel, textField)
        textField.addTarget(self, action: #selector(onTextFieldDidChangeText), for: .editingChanged)
        self.selectionStyle = .none
        self.separatorInset = .zero

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        titleLabel.font = UX.TitleLabelFont
        textField.font = UX.TextFieldFont

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.VerticalMargin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.HorizontalMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.HorizontalMargin),

            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.HorizontalMargin),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.HorizontalMargin),
            textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.VerticalMargin)
        ])
    }

    func configureCell(
        title: String,
        textFieldText: String,
        autocapitalizationType: UITextAutocapitalizationType,
        keyboardType: UIKeyboardType,
        textFieldAccessibilityIdentifier: String? = nil
    ) {
        titleLabel.text = title
        textField.text = textFieldText
        textField.autocapitalizationType = autocapitalizationType
        textField.keyboardType = keyboardType
        textField.accessibilityIdentifier = textFieldAccessibilityIdentifier
    }

    func focusTextField() {
        textField.becomeFirstResponder()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        backgroundColor = colors.layer5
        titleLabel.textColor = colors.textAccent
        textField.textColor = colors.textPrimary
        textField.tintColor = colors.actionPrimary
    }

    @objc
    private func onTextFieldDidChangeText() {
        if let text = textField.text {
            delegate?.textFieldTableViewCell(self, didChangeText: text)
        }
    }
}
