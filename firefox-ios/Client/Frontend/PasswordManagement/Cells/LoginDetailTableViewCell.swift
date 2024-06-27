// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared

protocol LoginDetailTableViewCellDelegate: AnyObject {
    func didSelectOpenAndFillForCell(_ cell: LoginDetailTableViewCell)
    func shouldReturnAfterEditingDescription(_ cell: LoginDetailTableViewCell) -> Bool
    func canPerform(action: Selector, for cell: LoginDetailTableViewCell) -> Bool
    func textFieldDidChange(_ cell: LoginDetailTableViewCell)
    func textFieldDidEndEditing(_ cell: LoginDetailTableViewCell)
}

struct LoginDetailTableViewCellModel {
    let title: String
    var description: String?
    var descriptionPlaceholder: String?
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var displayDescriptionAsPassword = false
    let a11yId: String
    var isEditingFieldData = false
    var cellType: LoginDetailTableViewCell.CellType {
        isEditingFieldData ? .editingFieldData: .standard
    }
}

class LoginDetailTableViewCell: UITableViewCell,
                                ThemeApplicable,
                                ReusableCell,
                                UITextFieldDelegate,
                                MenuHelperLoginInterface {
    private struct UX {
        static let horizontalMargin: CGFloat = 14
        static let verticalMargin: CGFloat = 11
    }

    enum CellType {
        case standard
        case editingFieldData
    }

    private var viewModel: LoginDetailTableViewCellModel?
    weak var delegate: LoginDetailTableViewCellDelegate?

    private lazy var labelContainer: UIView = .build { _ in }

    // In order for context menu handling, this is required
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return delegate?.canPerform(action: action, for: self) ?? false
    }

    lazy var descriptionLabel: UITextField = .build { [weak self] label in
        guard let self = self else { return }

        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.isUserInteractionEnabled = false
        label.autocapitalizationType = .none
        label.autocorrectionType = .no
        label.accessibilityElementsHidden = true
        label.delegate = self
        label.isAccessibilityElement = true
        label.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
    }

    private lazy var highlightedLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
    }

    /// Override the default accessibility label since it won't include the description by default
    /// since it's a UITextField acting as a label.
    override var accessibilityLabel: String? {
        get {
            if descriptionLabel.isSecureTextEntry {
                return highlightedLabel.text ?? ""
            } else {
                return "\(highlightedLabel.text ?? ""), \(descriptionLabel.text ?? "")"
            }
        }
        // swiftlint:disable unused_setter_value
        set { }
        // swiftlint:enable unused_setter_value
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        contentView.alpha = 1
        descriptionLabel.isSecureTextEntry = false
        descriptionLabel.keyboardType = .default
        descriptionLabel.returnKeyType = .default
        descriptionLabel.isUserInteractionEnabled = false
        separatorInset = .zero
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false
    }

    func configure(viewModel: LoginDetailTableViewCellModel) {
        self.viewModel = viewModel
        highlightedLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        descriptionLabel.placeholder = viewModel.descriptionPlaceholder
        descriptionLabel.keyboardType = viewModel.keyboardType
        descriptionLabel.returnKeyType = viewModel.returnKeyType
        descriptionLabel.accessibilityIdentifier = viewModel.a11yId
        descriptionLabel.isSecureTextEntry = viewModel.displayDescriptionAsPassword
        descriptionLabel.isUserInteractionEnabled = viewModel.isEditingFieldData

        if viewModel.displayDescriptionAsPassword {
            descriptionLabel.font = FXFontStyles.Regular.subheadline.monospacedFont()
        }
    }

    private func setupLayout() {
        labelContainer.addSubviews(highlightedLabel, descriptionLabel)
        contentView.addSubview(labelContainer)

        NSLayoutConstraint.activate([
            labelContainer.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                constant: UX.verticalMargin),
            labelContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                   constant: -UX.verticalMargin),
            labelContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: UX.horizontalMargin),
            labelContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: -UX.horizontalMargin),

            highlightedLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
            highlightedLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor),
            highlightedLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor),
            highlightedLabel.widthAnchor.constraint(equalTo: labelContainer.widthAnchor),

            descriptionLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: highlightedLabel.bottomAnchor),
            descriptionLabel.widthAnchor.constraint(equalTo: labelContainer.widthAnchor)
        ])

        setNeedsUpdateConstraints()
    }

    func applyTheme(theme: Theme) {
        guard let cellType = viewModel?.cellType else { return }

        switch cellType {
        case .standard:
            highlightedLabel.textColor = theme.colors.actionPrimary
        case .editingFieldData:
            highlightedLabel.textColor = theme.colors.textSecondary
        }

        descriptionLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer5
    }

    // MARK: - Menu Selectors
    func menuHelperReveal() {
        descriptionLabel.isSecureTextEntry = false
    }

    func menuHelperSecure() {
        descriptionLabel.isSecureTextEntry = true
    }

    func menuHelperCopy() {
        // Copy description text to clipboard
        UIPasteboard.general.string = descriptionLabel.text
    }

    func menuHelperOpenAndFill() {
        delegate?.didSelectOpenAndFillForCell(self)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.shouldReturnAfterEditingDescription(self) ?? true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let viewModel = viewModel, viewModel.displayDescriptionAsPassword {
            descriptionLabel.isSecureTextEntry = false
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let viewModel = viewModel, viewModel.displayDescriptionAsPassword {
            descriptionLabel.isSecureTextEntry = true
        }
        delegate?.textFieldDidEndEditing(self)
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) {
        delegate?.textFieldDidChange(self)
    }
}
