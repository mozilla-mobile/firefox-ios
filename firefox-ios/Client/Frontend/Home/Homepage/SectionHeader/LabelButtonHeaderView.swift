// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation

/// Firefox homepage section header view
class LabelButtonHeaderView: UICollectionReusableView,
                             ReusableCell,
                             ThemeApplicable,
                             Notifiable {
    struct UX {
        static let inBetweenSpace: CGFloat = 12
        static let topSpacing: CGFloat = 0
        static let bottomSpace: CGFloat = 16
        static let bottomButtonSpace: CGFloat = 6
        static let leadingInset: CGFloat = 0
        static let blurCornerRadius: CGFloat = 12
        static let blurHorizontalPadding: CGFloat = 10
        static let blurVerticalPadding: CGFloat = 6
    }

    // MARK: - UIElements

    /// Frosted-glass background — visible only when `showsBlurBackground` is `true`
    private lazy var blurBackgroundView: UIVisualEffectView = .build { view in
        view.effect = UIBlurEffect(style: .systemMaterial)
        view.layer.cornerRadius = UX.blurCornerRadius
        view.layer.masksToBounds = true
        view.isHidden = true
    }

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
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

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

        addSubview(blurBackgroundView)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topSpacing),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.leadingInset),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpace),

            blurBackgroundView.topAnchor.constraint(
                equalTo: stackView.topAnchor,
                constant: -UX.blurVerticalPadding
            ),
            blurBackgroundView.leadingAnchor.constraint(
                equalTo: stackView.leadingAnchor,
                constant: -UX.blurHorizontalPadding
            ),
            blurBackgroundView.trailingAnchor.constraint(
                equalTo: stackView.trailingAnchor,
                constant: UX.blurHorizontalPadding
            ),
            blurBackgroundView.bottomAnchor.constraint(
                equalTo: stackView.bottomAnchor,
                constant: UX.blurVerticalPadding
            )
        ])

        // Setting custom values to resolve horizontal ambiguity
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        titleLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)

        adjustLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helper functions
    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        blurBackgroundView.isHidden = true
    }

    func configure(
        state: SectionHeaderConfiguration,
        moreButtonAction: (@MainActor (UIButton) -> Void)? = nil,
        textColor: UIColor?,
        theme: Theme
    ) {
        self.title = state.title
        titleLabel.accessibilityIdentifier = state.a11yIdentifier

        moreButton.isHidden = state.isButtonHidden
        if !state.isButtonHidden {
            let moreButtonViewModel = ActionButtonViewModel(
                title: state.buttonTitle ?? .BookmarksSavedShowAllText,
                a11yIdentifier: state.buttonA11yIdentifier,
                touchUpAction: moreButtonAction
            )
            moreButton.configure(
                viewModel: moreButtonViewModel
            )
        }

        blurBackgroundView.isHidden = !state.showsBlurBackground

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
