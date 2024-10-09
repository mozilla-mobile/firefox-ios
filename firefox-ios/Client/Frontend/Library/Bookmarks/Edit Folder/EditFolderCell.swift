// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ComponentLibrary

class EditFolderCell: UITableViewCell,
                      ReusableCell,
                      ThemeApplicable {
    private struct UX {
        static let textFieldVerticalPadding: CGFloat = 12.0
        static let textFieldHorizontalPadding: CGFloat = 16.0
    }
    private lazy var titleTextField: TextField = .build { view in
        view.addAction(UIAction(handler: { [weak self] _ in
            self?.titleTextFieldDidChange()
        }), for: .editingChanged)
    }
    var onTitleFieldUpdate: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return titleTextField.becomeFirstResponder()
    }

    private func setupSubviews() {
        titleTextField.placeholder = .BookmarkDetailFieldTitle
        contentView.addSubview(titleTextField)
        NSLayoutConstraint.activate([
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: UX.textFieldHorizontalPadding),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: -UX.textFieldHorizontalPadding),
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                constant: UX.textFieldVerticalPadding),
            titleTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                   constant: -UX.textFieldVerticalPadding)
        ])
    }

    func setTitle(_ title: String?) {
        titleTextField.text = title
    }

    private func titleTextFieldDidChange() {
        onTitleFieldUpdate?(titleTextField.text ?? "")
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        titleTextField.applyTheme(theme: theme)
        contentView.backgroundColor = theme.colors.layer2
    }
}
