// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation

/// Firefox homepage section header view
class LabelButtonHeaderView: UIView, ThemeApplicable, Notifiable {
    struct UX {
        static let inBetweenSpace: CGFloat = 12
    }

    // MARK: - UIElements
    private lazy var stackView: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = UX.inBetweenSpace
        stackView.alignment = .fill
        stackView.distribution = .fill
    }

    lazy var titleLabel: UILabel = .build { label in
        label.text = self.title
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private(set) lazy var moreButton: ActionButton = .build { button in
        button.isHidden = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)

        var updatedConfiguration = button.configuration
        updatedConfiguration?.titleLineBreakMode = .byTruncatingTail
        button.configuration = updatedConfiguration
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var bottomConstraint: NSLayoutConstraint?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    private func setupLayout() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(moreButton)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        adjustLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helper functions
    func prepareForReuse() {
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    func configure(
        sectionHeaderConfiguration: SectionHeaderConfiguration,
        moreButtonAction: (@MainActor (UIButton) -> Void)? = nil,
        textColor: UIColor?,
        theme: Theme
    ) {
        self.title = sectionHeaderConfiguration.title
        titleLabel.accessibilityIdentifier = sectionHeaderConfiguration.a11yIdentifier

        moreButton.isHidden = sectionHeaderConfiguration.isButtonHidden
        if !sectionHeaderConfiguration.isButtonHidden {
            let moreButtonViewModel = ActionButtonViewModel(
                title: sectionHeaderConfiguration.buttonTitle ?? .BookmarksSavedShowAllText,
                a11yIdentifier: sectionHeaderConfiguration.buttonA11yIdentifier,
                touchUpAction: moreButtonAction
            )
            moreButton.configure(
                viewModel: moreButtonViewModel
            )
        }

        if let color = textColor {
            applyTextColors(color: color)
        } else {
            applyTheme(theme: theme)
        }
    }

    // MARK: - Dynamic Type Support
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != self.traitCollection.preferredContentSizeCategory {
            adjustLayout()
        }
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            stackView.axis = .vertical
            moreButton.contentHorizontalAlignment = .leading
        } else {
            stackView.axis = .horizontal
            moreButton.contentHorizontalAlignment = .trailing
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    private func applyTextColors(color: UIColor) {
        titleLabel.textColor = color
        moreButton.foregroundColorNormal = color
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        moreButton.foregroundColorNormal = theme.colors.textAccent
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        let name = notification.name
        ensureMainThread {
            switch name {
            case UIContentSizeCategory.didChangeNotification:
                self.adjustLayout()
            default: break
            }
        }
    }
}
