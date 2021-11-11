// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit
import Storage

protocol LoginDetailTableViewCellDelegate: AnyObject {
    func didSelectOpenAndFillForCell(_ cell: LoginDetailTableViewCell)
    func shouldReturnAfterEditingDescription(_ cell: LoginDetailTableViewCell) -> Bool
    func canPeform(action: Selector, for cell: LoginDetailTableViewCell) -> Bool
    func textFieldDidChange(_ cell: LoginDetailTableViewCell)
    func textFieldDidEndEditing(_ cell: LoginDetailTableViewCell)
}

public struct LoginTableViewCellUX {
    static let highlightedLabelFont = UIFont.systemFont(ofSize: 12)
    static let highlightedLabelTextColor = UIConstants.SystemBlueColor
    static let descriptionLabelFont = UIFont.systemFont(ofSize: 16)
    static let HorizontalMargin: CGFloat = 14
}

enum LoginTableViewCellStyle {
    case iconAndBothLabels
    case noIconAndBothLabels
    case iconAndDescriptionLabel
}

class LoginDetailTableViewCell: ThemedTableViewCell {

    fileprivate let labelContainer = UIView()

    weak var delegate: LoginDetailTableViewCellDelegate?

    // In order for context menu handling, this is required
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return delegate?.canPeform(action: action, for: self) ?? false
    }

    lazy var descriptionLabel: UITextField = {
        let label = UITextField()
        label.font = LoginTableViewCellUX.descriptionLabelFont
        label.isUserInteractionEnabled = false
        label.autocapitalizationType = .none
        label.autocorrectionType = .no
        label.accessibilityElementsHidden = true
        label.adjustsFontSizeToFitWidth = false
        label.delegate = self
        label.isAccessibilityElement = true
        label.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        return label
    }()

    // Exposing this label as internal/public causes the Xcode 7.2.1 compiler optimizer to
    // produce a EX_BAD_ACCESS error when dequeuing the cell. For now, this label is made private
    // and the text property is exposed using a get/set property below.
    fileprivate lazy var highlightedLabel: UILabel = {
        let label = UILabel()
        label.font = LoginTableViewCellUX.highlightedLabelFont
        label.textColor = LoginTableViewCellUX.highlightedLabelTextColor
        label.numberOfLines = 1
        return label
    }()

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
        set {
            // Ignore sets
        }
    }

    var descriptionTextSize: CGSize? {
        guard let descriptionText = descriptionLabel.text else {
            return nil
        }

        let attributes = [
            NSAttributedString.Key.font: LoginTableViewCellUX.descriptionLabelFont
        ]

        return descriptionText.size(withAttributes: attributes)
    }
    
    var placeholder: String? {
        get { descriptionLabel.placeholder }
        set { descriptionLabel.placeholder = newValue }
    }

    var displayDescriptionAsPassword: Bool = false {
        didSet {
            descriptionLabel.isSecureTextEntry = displayDescriptionAsPassword
        }
    }

    var isEditingFieldData: Bool = false {
        didSet {
            guard isEditingFieldData != oldValue else { return }
            descriptionLabel.isUserInteractionEnabled = isEditingFieldData
            highlightedLabel.textColor = isEditingFieldData ? UIColor.theme.tableView.headerTextLight: LoginTableViewCellUX.highlightedLabelTextColor
        }
    }

    var highlightedLabelTitle: String? {
        get {
            return highlightedLabel.text
        }
        set(newTitle) {
            highlightedLabel.text = newTitle
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        labelContainer.addSubview(highlightedLabel)
        labelContainer.addSubview(descriptionLabel)
        contentView.addSubview(labelContainer)

        configureLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        descriptionLabel.isSecureTextEntry = false
        descriptionLabel.keyboardType = .default
        descriptionLabel.returnKeyType = .default
        descriptionLabel.isUserInteractionEnabled = false
    }

    fileprivate func configureLayout() {
        labelContainer.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
            make.leading.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
        }

        highlightedLabel.snp.remakeConstraints { make in
            make.leading.top.equalTo(labelContainer)
            make.bottom.equalTo(descriptionLabel.snp.top)
            make.width.equalTo(labelContainer)
        }

        descriptionLabel.snp.remakeConstraints { make in
            make.leading.bottom.equalTo(labelContainer)
            make.top.equalTo(highlightedLabel.snp.bottom)
            make.width.equalTo(labelContainer)
        }

        setNeedsUpdateConstraints()
    }

    override func applyTheme() {
        super.applyTheme()
        descriptionLabel.textColor = UIColor.theme.tableView.rowText
    }
}

// MARK: - Menu Selectors
extension LoginDetailTableViewCell: MenuHelperInterface {

    func menuHelperReveal() {
        displayDescriptionAsPassword = false
    }

    func menuHelperSecure() {
        displayDescriptionAsPassword = true
    }

    func menuHelperCopy() {
        // Copy description text to clipboard
        UIPasteboard.general.string = descriptionLabel.text
    }

    func menuHelperOpenAndFill() {
        delegate?.didSelectOpenAndFillForCell(self)
    }
}

// MARK: - Cell Decorators
extension LoginDetailTableViewCell {
    func updateCellWithLogin(_ login: LoginRecord) {
        descriptionLabel.text = login.hostname
        highlightedLabel.text = login.decryptedUsername
    }
}

extension LoginDetailTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.delegate?.shouldReturnAfterEditingDescription(self) ?? true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if descriptionLabel.isSecureTextEntry {
            displayDescriptionAsPassword = false
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if descriptionLabel.isSecureTextEntry {
            displayDescriptionAsPassword = true
        }
        delegate?.textFieldDidEndEditing(self)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.textFieldDidChange(self)
    }
}
