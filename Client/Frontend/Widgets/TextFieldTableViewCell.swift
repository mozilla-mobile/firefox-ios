// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

struct TextFieldTableViewCellUX {
    static let HorizontalMargin: CGFloat = 16
    static let VerticalMargin: CGFloat = 10
    static let TitleLabelFont = UIFont.systemFont(ofSize: 12)
    static let TitleLabelTextColor = UIConstants.SystemBlueColor
    static let TextFieldFont = UIFont.systemFont(ofSize: 16)
}

protocol TextFieldTableViewCellDelegate: AnyObject {
    func textFieldTableViewCell(_ textFieldTableViewCell: TextFieldTableViewCell, didChangeText text: String)
}

class TextFieldTableViewCell: UITableViewCell, NotificationThemeable {
    let titleLabel: UILabel
    let textField: UITextField

    weak var delegate: TextFieldTableViewCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.titleLabel = UILabel(frame: .zero)
        self.textField = UITextField(frame: .zero)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        self.textField.delegate = self
        self.selectionStyle = .none
        self.separatorInset = .zero
        self.applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.font = TextFieldTableViewCellUX.TitleLabelFont
        titleLabel.snp.remakeConstraints { make in
            guard let _ = titleLabel.superview else { return }

            make.leading.equalTo(TextFieldTableViewCellUX.HorizontalMargin)
            make.trailing.equalTo(-TextFieldTableViewCellUX.HorizontalMargin)
            make.top.equalTo(TextFieldTableViewCellUX.VerticalMargin)
        }

        textField.font = TextFieldTableViewCellUX.TextFieldFont
        textField.snp.remakeConstraints { make in
            guard let _ = textField.superview else { return }

            make.leading.equalTo(TextFieldTableViewCellUX.HorizontalMargin)
            make.trailing.equalTo(-TextFieldTableViewCellUX.HorizontalMargin)
            make.bottom.equalTo(-TextFieldTableViewCellUX.VerticalMargin)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.tableView.rowBackground
        titleLabel.textColor = TextFieldTableViewCellUX.TitleLabelTextColor
        textField.textColor = UIColor.theme.tableView.rowText
    }
}

extension TextFieldTableViewCell: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange, with: string)
            delegate?.textFieldTableViewCell(self, didChangeText: updatedText)
        }
        return true
    }
}
