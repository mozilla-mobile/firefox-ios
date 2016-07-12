/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage

@objc
protocol LoginTableViewCellDelegate: class {
    func didSelectOpenAndFill(forCell cell: LoginTableViewCell)
    func shouldReturnAfterEditingDescription(_ cell: LoginTableViewCell) -> Bool
}

private struct LoginTableViewCellUX {
    static let highlightedLabelFont = UIFont.systemFont(ofSize: 12)
    static let highlightedLabelTextColor = UIConstants.HighlightBlue
    static let highlightedLabelEditingTextColor = UIConstants.TableViewHeaderTextColor

    static let descriptionLabelFont = UIFont.systemFont(ofSize: 16)
    static let descriptionLabelTextColor = UIColor.black()

    static let HorizontalMargin: CGFloat = 14
    static let IconImageSize: CGFloat = 34

    static let indentWidth: CGFloat = 44
    static let IndentAnimationDuration: TimeInterval = 0.2

    static let editingDescriptionIndent: CGFloat = IconImageSize + HorizontalMargin
}

enum LoginTableViewCellStyle {
    case iconAndBothLabels
    case noIconAndBothLabels
    case iconAndDescriptionLabel
}

class LoginTableViewCell: UITableViewCell {

    private let labelContainer = UIView()

    weak var delegate: LoginTableViewCellDelegate? = nil

    lazy var descriptionLabel: UITextField = {
        let label = UITextField()
        label.font = LoginTableViewCellUX.descriptionLabelFont
        label.textColor = LoginTableViewCellUX.descriptionLabelTextColor
        label.textAlignment = .left
        label.backgroundColor = UIColor.white()
        label.isUserInteractionEnabled = false
        label.autocapitalizationType = .none
        label.autocorrectionType = .no
        label.accessibilityElementsHidden = true
        label.adjustsFontSizeToFitWidth = false
        label.delegate = self
        return label
    }()

    // Exposing this label as internal/public causes the Xcode 7.2.1 compiler optimizer to
    // produce a EX_BAD_ACCESS error when dequeuing the cell. For now, this label is made private
    // and the text property is exposed using a get/set property below.
    private lazy var highlightedLabel: UILabel = {
        let label = UILabel()
        label.font = LoginTableViewCellUX.highlightedLabelFont
        label.textColor = LoginTableViewCellUX.highlightedLabelTextColor
        label.textAlignment = .left
        label.backgroundColor = UIColor.white()
        label.numberOfLines = 1
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.white()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var showingIndent: Bool = false

    private var customIndentView = UIView()

    private var customCheckmarkIcon = UIImageView(image: UIImage(named: "loginUnselected"))

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

    var style: LoginTableViewCellStyle = .iconAndBothLabels {
        didSet {
            if style != oldValue {
                configureLayout(forStyle: style)
            }
        }
    }

    var descriptionTextSize: CGSize? {
        guard let descriptionText = descriptionLabel.text else {
            return nil
        }

        let attributes = [
            NSFontAttributeName: LoginTableViewCellUX.descriptionLabelFont
        ]

        return descriptionText.size(attributes: attributes)
    }

    var displayDescriptionAsPassword: Bool = false {
        didSet {
            descriptionLabel.isSecureTextEntry = displayDescriptionAsPassword
        }
    }

    var editingDescription: Bool = false {
        didSet {
            if editingDescription != oldValue {
                descriptionLabel.isUserInteractionEnabled = editingDescription

                highlightedLabel.textColor = editingDescription ?
                    LoginTableViewCellUX.highlightedLabelEditingTextColor : LoginTableViewCellUX.highlightedLabelTextColor

                // Trigger a layout configuration if we changed to editing/not editing the description.
                configureLayout(forStyle: self.style)
            }
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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        indentationWidth = 0
        selectionStyle = .none

        contentView.backgroundColor = UIColor.white()
        labelContainer.backgroundColor = UIColor.white()

        labelContainer.addSubview(highlightedLabel)
        labelContainer.addSubview(descriptionLabel)

        contentView.addSubview(iconImageView)
        contentView.addSubview(labelContainer)

        customIndentView.addSubview(customCheckmarkIcon)
        addSubview(customIndentView)

        configureLayout(forStyle: self.style)
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

    override func layoutSubviews() {
        super.layoutSubviews()

        // Adjust indent frame
        var indentFrame = CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: LoginTableViewCellUX.indentWidth, height: frame.height))

        if !showingIndent{
            indentFrame.origin.x = -LoginTableViewCellUX.indentWidth
        }

        customIndentView.frame = indentFrame
        customCheckmarkIcon.frame.center = CGPoint(x: indentFrame.width / 2, y: indentFrame.height / 2)

        // Adjust content view frame based on indent
        var contentFrame = self.contentView.frame
        contentFrame.origin.x += showingIndent ? LoginTableViewCellUX.indentWidth : 0
        contentView.frame = contentFrame
    }

    private func configureLayout(forStyle style: LoginTableViewCellStyle) {
        switch style {
        case .iconAndBothLabels:
            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(LoginTableViewCellUX.IconImageSize)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right).offset(LoginTableViewCellUX.HorizontalMargin)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.left.top.equalTo(labelContainer)
                make.bottom.equalTo(descriptionLabel.snp_top)
                make.width.equalTo(labelContainer)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.left.bottom.equalTo(labelContainer)
                make.top.equalTo(highlightedLabel.snp_bottom)
                make.width.equalTo(labelContainer)
            }
        case .iconAndDescriptionLabel:
            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(LoginTableViewCellUX.IconImageSize)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right).offset(LoginTableViewCellUX.HorizontalMargin)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.height.width.equalTo(0)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.top.left.bottom.equalTo(labelContainer)
                make.width.equalTo(labelContainer)
            }
        case .noIconAndBothLabels:
            // Currently we only support modifying the description for this layout which is why
            // we factor in the editingOffset when calculating the constraints.
            let editingOffset = editingDescription ? LoginTableViewCellUX.editingDescriptionIndent : 0

            iconImageView.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.left.equalTo(contentView).offset(LoginTableViewCellUX.HorizontalMargin)
                make.height.width.equalTo(0)
            }

            labelContainer.snp_remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.right.equalTo(contentView).offset(-LoginTableViewCellUX.HorizontalMargin)
                make.left.equalTo(iconImageView.snp_right).offset(editingOffset)
            }

            highlightedLabel.snp_remakeConstraints { make in
                make.left.top.equalTo(labelContainer)
                make.bottom.equalTo(descriptionLabel.snp_top)
                make.width.equalTo(labelContainer)
            }

            descriptionLabel.snp_remakeConstraints { make in
                make.left.bottom.equalTo(labelContainer)
                make.top.equalTo(highlightedLabel.snp_bottom)
                make.width.equalTo(labelContainer)
            }
        }

        setNeedsUpdateConstraints()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        showingIndent = editing

        let adjustConstraints = { [unowned self] in

            // Shift over content view
            var contentFrame = self.contentView.frame
            contentFrame.origin.x += editing ? LoginTableViewCellUX.indentWidth : -LoginTableViewCellUX.indentWidth
            self.contentView.frame = contentFrame

            // Shift over custom indent view
            var indentFrame = self.customIndentView.frame
            indentFrame.origin.x += editing ? LoginTableViewCellUX.indentWidth : -LoginTableViewCellUX.indentWidth
            self.customIndentView.frame = indentFrame
        }

        animated ? UIView.animate(withDuration: LoginTableViewCellUX.IndentAnimationDuration, animations: adjustConstraints) : adjustConstraints()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        customCheckmarkIcon.image = UIImage(named: selected ? "loginSelected" : "loginUnselected")
    }
}

// MARK: - Menu Selectors
extension LoginTableViewCell: MenuHelperInterface {

    func menuHelperReveal(_ sender: Notification) {
        displayDescriptionAsPassword = false
    }

    func menuHelperSecure(_ sender: Notification) {
        displayDescriptionAsPassword = true
    }

    func menuHelperCopy(_ sender: Notification) {
        // Copy description text to clipboard
        UIPasteboard.general().string = descriptionLabel.text
    }

    func menuHelperOpenAndFill(_ sender: Notification) {
        delegate?.didSelectOpenAndFill(forCell: self)
    }
}

// MARK: - Cell Decorators
extension LoginTableViewCell {
    func updateCellWithLogin(_ login: LoginData) {
        descriptionLabel.text = login.hostname
        highlightedLabel.text = login.username
        iconImageView.image = UIImage(named: "faviconFox")
    }
}

extension LoginTableViewCell: UITextFieldDelegate {
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
    }
}
