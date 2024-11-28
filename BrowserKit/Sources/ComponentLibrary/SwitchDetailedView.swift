// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct SwitchDetailedViewModel {
    public init(contentStackViewA11yId: String,
                actionContentViewA11yId: String,
                actionTitleLabelA11yId: String,
                actionSwitchA11yId: String,
                actionDescriptionLabelA11yId: String) {
        self.contentStackViewA11yId = contentStackViewA11yId
        self.actionContentViewA11yId = actionContentViewA11yId
        self.actionTitleLabelA11yId = actionTitleLabelA11yId
        self.actionSwitchA11yId = actionSwitchA11yId
        self.actionDescriptionLabelA11yId = actionDescriptionLabelA11yId
    }

    public let contentStackViewA11yId: String
    public let actionContentViewA11yId: String
    public let actionTitleLabelA11yId: String
    public let actionSwitchA11yId: String
    public let actionDescriptionLabelA11yId: String
}

public class SwitchDetailedView: UIView, ThemeApplicable {
    private struct UX {
        static let actionContentViewMargin: CGFloat = 11
        static let actionContentViewRightMargin: CGFloat = 16
        static let contentDistance: CGFloat = 12
        static let actionContentCornerRadius: CGFloat = 12
        static let actionContentDistance: CGFloat = 6
    }

    // MARK: - Properties
    public var switchCallback: ((_ isOn: Bool) -> Void)?
    public var learnMoreCallBack: (() -> Void)?

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.contentDistance
    }

    private lazy var actionContentView: UIView = .build { view in
        view.layer.masksToBounds = true
        view.layer.cornerRadius = UX.actionContentCornerRadius
    }

    private lazy var actionTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    private lazy var actionSwitch: UISwitch = .build { switchView in
        switchView.addTarget(self, action: #selector(self.switchValueChanged), for: .valueChanged)
    }

    private lazy var actionDescriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(actionContentView)
        actionContentView.addSubview(actionTitleLabel)
        actionContentView.addSubview(actionSwitch)
        contentStackView.addArrangedSubview(actionDescriptionLabel)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            actionTitleLabel.leadingAnchor.constraint(
                equalTo: actionContentView.leadingAnchor,
                constant: UX.actionContentViewMargin
            ),
            actionTitleLabel.trailingAnchor.constraint(
                equalTo: actionSwitch.leadingAnchor,
                constant: -UX.actionContentDistance
            ),
            actionTitleLabel.topAnchor.constraint(
                equalTo: actionContentView.topAnchor,
                constant: UX.actionContentViewMargin
            ),
            actionTitleLabel.bottomAnchor.constraint(
                equalTo: actionContentView.bottomAnchor,
                constant: -UX.actionContentViewMargin
            ),

            actionSwitch.trailingAnchor.constraint(
                equalTo: actionContentView.trailingAnchor,
                constant: -UX.actionContentViewRightMargin
            ),
            actionSwitch.centerYAnchor.constraint(
                equalTo: actionTitleLabel.centerYAnchor
            )
        ])
    }

    public func configure(viewModel: SwitchDetailedViewModel) {
        contentStackView.accessibilityIdentifier = viewModel.contentStackViewA11yId
        actionContentView.accessibilityIdentifier = viewModel.actionContentViewA11yId
        actionTitleLabel.accessibilityIdentifier = viewModel.actionTitleLabelA11yId
        actionSwitch.accessibilityIdentifier = viewModel.actionSwitchA11yId
        actionDescriptionLabel.accessibilityIdentifier = viewModel.actionDescriptionLabelA11yId
    }

    public func setupDetails(actionTitle: String,
                             actionDescription: String,
                             linkDescription: String,
                             theme: Theme
    ) {
        actionTitleLabel.text = actionTitle
        let description = String(format: actionDescription, linkDescription)
        let linkedDescription = NSMutableAttributedString(string: description)
        let linkedText = (description as NSString).range(of: linkDescription)
        linkedDescription.addAttribute(.font,
                                       value: FXFontStyles.Regular.caption1.scaledFont(),
                                       range: NSRange(location: 0, length: description.count))
        linkedDescription.addAttribute(.foregroundColor,
                                       value: theme.colors.textPrimary,
                                       range: NSRange(location: 0, length: description.count))
        linkedDescription.addAttribute(.foregroundColor,
                                       value: theme.colors.textAccent,
                                       range: linkedText)
        actionDescriptionLabel.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped))
        actionDescriptionLabel.addGestureRecognizer(gesture)
        actionDescriptionLabel.attributedText = linkedDescription
    }

    // MARK: - Button actions
    @objc
    private func switchValueChanged(_ sender: UISwitch) {
        switchCallback?(sender.isOn)
    }

    @objc
    private func learnMoreTapped(_ gesture: UIGestureRecognizer) {
        learnMoreCallBack?()
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: any Theme) {
        backgroundColor = .clear
        actionContentView.backgroundColor = theme.colors.layer5
        actionTitleLabel.textColor = theme.colors.textPrimary
        actionSwitch.onTintColor = theme.colors.actionPrimary
    }
}
