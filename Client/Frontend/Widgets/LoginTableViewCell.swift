/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage

@objc
protocol LoginTableViewCellDelegate: class {
    func didSelectOpenAndFillForCell(cell: LoginTableViewCell)
}

private struct LoginTableViewCellUX {
    static let highlightedLabelFont = UIFont.systemFontOfSize(12)
    static let highlightedLabelTextColor = UIConstants.HighlightBlue
    static let highlightedLabelEditingTextColor = UIConstants.TableViewHeaderTextColor

    static let descriptionLabelFont = UIFont.systemFontOfSize(16)
    static let descriptionLabelTextColor = UIColor.blackColor()

    static let HorizontalMargin: CGFloat = 14
    static let IconImageSize: CGFloat = 34

    static let indentWidth: CGFloat = 44
    static let IndentAnimationDuration: NSTimeInterval = 0.2

    static let editingDescriptionIndent: CGFloat = IconImageSize + HorizontalMargin
}

enum LoginTableViewCellStyle {
    case IconAndBothLabels
    case NoIconAndBothLabels
    case IconAndDescriptionLabel
}

enum LoginTableViewCellActions {
    case OpenAndFill
    case Reveal
    case Hide
    case Copy
}

class LoginTableViewCell: UITableViewCell {

    private let labelContainer = UIView()

    weak var delegate: LoginTableViewCellDelegate? = nil

    lazy var descriptionLabel: UITextField = {
        let label = UITextField()
        label.font = LoginTableViewCellUX.descriptionLabelFont
        label.textColor = LoginTableViewCellUX.descriptionLabelTextColor
        label.textAlignment = .Left
        label.backgroundColor = UIColor.whiteColor()
        label.userInteractionEnabled = false
        label.autocapitalizationType = .None
        label.autocorrectionType = .No
        label.accessibilityElementsHidden = true
        label.adjustsFontSizeToFitWidth = false
        return label
    }()

    lazy var highlightedLabel: UILabel = {
        let label = UILabel()
        label.font = LoginTableViewCellUX.highlightedLabelFont
        label.textColor = LoginTableViewCellUX.highlightedLabelTextColor
        label.textAlignment = .Left
        label.backgroundColor = UIColor.whiteColor()
        label.numberOfLines = 1
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.whiteColor()
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()

    private var showingIndent: Bool = false

    private var customIndentView = UIView()

    private var customCheckmarkIcon = UIImageView(image: UIImage(named: "loginUnselected"))

    /// Override the default accessibility label since it won't include the description by default
    /// since it's a UITextField acting as a label.
    override var accessibilityLabel: String? {
        get {
            if descriptionLabel.secureTextEntry {
                return highlightedLabel.text ?? ""
            } else {
                return "\(highlightedLabel.text ?? ""), \(descriptionLabel.text ?? "")"
            }
        }
        set {
            // Ignore sets
        }
    }

    var enabledActions = [LoginTableViewCellActions]()

    var style: LoginTableViewCellStyle = .IconAndBothLabels {
        didSet {
            if style != oldValue {
                configureLayoutForStyle(style)
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

        return descriptionText.sizeWithAttributes(attributes)
    }

    var displayDescriptionAsPassword: Bool = false {
        didSet {
            descriptionLabel.secureTextEntry = displayDescriptionAsPassword

            // If we're editing only allow copy and hide reveal/hide
            if descriptionLabel.editing {
                enabledActions = [.Copy]
                return
            }

            if displayDescriptionAsPassword {
                enabledActions = [.Copy, .Reveal]
            } else {
                enabledActions = [.Copy, .Hide]
            }
        }
    }

    var editingDescription: Bool = false {
        didSet {
            if editingDescription != oldValue {
                descriptionLabel.userInteractionEnabled = editingDescription

                highlightedLabel.textColor = editingDescription ?
                    LoginTableViewCellUX.highlightedLabelEditingTextColor : LoginTableViewCellUX.highlightedLabelTextColor

                // Trigger a layout configuration if we changed to editing/not editing the description.
                configureLayoutForStyle(self.style)
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        indentationWidth = 0
        selectionStyle = .None

        contentView.backgroundColor = UIColor.whiteColor()
        labelContainer.backgroundColor = UIColor.whiteColor()

        labelContainer.addSubview(highlightedLabel)
        labelContainer.addSubview(descriptionLabel)

        contentView.addSubview(iconImageView)
        contentView.addSubview(labelContainer)

        customIndentView.addSubview(customCheckmarkIcon)
        addSubview(customIndentView)

        configureLayoutForStyle(self.style)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        enabledActions = []
        delegate = nil
        descriptionLabel.secureTextEntry = false
        descriptionLabel.keyboardType = .Default
        descriptionLabel.returnKeyType = .Default
        descriptionLabel.userInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Adjust indent frame
        var indentFrame = CGRect(
            origin: CGPointZero,
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

    private func configureLayoutForStyle(style: LoginTableViewCellStyle) {
        switch style {
        case .IconAndBothLabels:
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
        case .IconAndDescriptionLabel:
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
        case .NoIconAndBothLabels:
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

    override func setEditing(editing: Bool, animated: Bool) {
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

        animated ? UIView.animateWithDuration(LoginTableViewCellUX.IndentAnimationDuration, animations: adjustConstraints) : adjustConstraints()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        customCheckmarkIcon.image = UIImage(named: selected ? "loginSelected" : "loginUnselected")
    }
}

// MARK: - Menu Action Overrides
extension LoginTableViewCell {

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        let checks: [Bool] = enabledActions.map { actionEnum in
            switch actionEnum {
            case .OpenAndFill:
                return action == MenuHelper.SelectorOpenAndFill
            case .Reveal:
                return action == MenuHelper.SelectorReveal
            case .Hide:
                return action == MenuHelper.SelectorHide
            case .Copy:
                return action == MenuHelper.SelectorCopy
            }
        }

        return checks.contains(true)
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
}

// MARK: - Menu Selectors
extension LoginTableViewCell: MenuHelperInterface {

    func menuHelperReveal(sender: NSNotification) {
        displayDescriptionAsPassword = false
    }

    func menuHelperSecure(sender: NSNotification) {
        displayDescriptionAsPassword = true
    }

    func menuHelperCopy(sender: NSNotification) {
        // Copy description text to clipboard
        UIPasteboard.generalPasteboard().string = descriptionLabel.text
    }

    func menuHelperOpenAndFill(sender: NSNotification) {
        delegate?.didSelectOpenAndFillForCell(self)
    }
}

// MARK: - Cell Decorators
extension LoginTableViewCell {
    func updateCellWithLogin(login: LoginData) {
        descriptionLabel.text = login.hostname
        highlightedLabel.text = login.username
        iconImageView.image = UIImage(named: "faviconFox")
    }
}
