// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation

/// Firefox homepage section header view.
/// The section title is rendered as an underlined button; the trailing "Show All" button is hidden.
class LabelButtonHeaderView: UICollectionReusableView,
                             ReusableCell,
                             ThemeApplicable,
                             Notifiable {
    struct UX {
        static let topSpacing: CGFloat = 0
        static let bottomSpace: CGFloat = 16
        static let leadingInset: CGFloat = 0
        static let blurCornerRadius: CGFloat = 10
        static let blurHorizontalPadding: CGFloat = 8
        static let blurVerticalPadding: CGFloat = 4
    }

    // MARK: - UIElements

    /// Solid pill behind the title button using the same `layer5` color as homepage cards.
    /// Visible only when `showsBlurBackground` is `true`.
    private lazy var titleBackgroundView: UIView = .build { view in
        view.layer.cornerRadius = UX.blurCornerRadius
        view.layer.masksToBounds = true
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }

    /// The section title rendered as an underlined tappable button.
    lazy var titleButton: UIButton = .build { button in
        button.backgroundColor = .clear
        button.titleLabel?.font = FXFontStyles.Bold.title3.scaledFont()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 0
        button.accessibilityTraits = [.header, .button]
        button.contentHorizontalAlignment = .leading
    }

    /// Kept for API compatibility but always hidden.
    private(set) lazy var moreButton: ActionButton = .build { button in
        button.isHidden = true
    }

    // MARK: - Variables

    var title: String? {
        willSet(newTitle) {
            applyUnderlinedTitle(newTitle, color: titleButton.titleColor(for: .normal) ?? .label)
        }
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var titleButtonAction: (@MainActor (UIButton) -> Void)?

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        titleButton.addTarget(self, action: #selector(handleTitleTap), for: .touchUpInside)

        // Background sits behind button; button is inserted last so it renders on top.
        addSubview(titleBackgroundView)
        addSubview(titleButton)

        let hPad = UX.blurHorizontalPadding
        let vPad = UX.blurVerticalPadding

        // Title button: pinned top/leading/bottom, hugs its text width (no trailing constraint —
        // intrinsic size drives width via high hugging priority).
        NSLayoutConstraint.activate([
            titleButton.topAnchor.constraint(equalTo: topAnchor, constant: UX.topSpacing),
            titleButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.leadingInset),
            titleButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpace),

            // Background pill: constrained directly to titleButton edges + padding.
            // Auto Layout sizes it correctly on every pass without any frame math.
            titleBackgroundView.topAnchor.constraint(equalTo: titleButton.topAnchor, constant: -vPad),
            titleBackgroundView.leadingAnchor.constraint(
                equalTo: titleButton.leadingAnchor,
                constant: -hPad
            ),
            titleBackgroundView.trailingAnchor.constraint(
                equalTo: titleButton.trailingAnchor,
                constant: hPad
            ),
            titleBackgroundView.bottomAnchor.constraint(
                equalTo: titleButton.bottomAnchor,
                constant: vPad
            )
        ])

        // High hugging so button shrinks to its text width, not full cell width.
        titleButton.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        titleButton.setContentHuggingPriority(UILayoutPriority(751), for: .horizontal)
    }

    // MARK: - Helper functions

    override func prepareForReuse() {
        super.prepareForReuse()
        titleButton.setAttributedTitle(nil, for: .normal)
        titleButton.accessibilityIdentifier = nil
        titleButtonAction = nil
        titleBackgroundView.isHidden = true
        moreButton.isHidden = true
    }

    func configure(
        state: SectionHeaderConfiguration,
        moreButtonAction: (@MainActor (UIButton) -> Void)? = nil,
        textColor: UIColor?,
        theme: Theme
    ) {
        self.titleButtonAction = moreButtonAction
        self.title = state.title
        titleButton.accessibilityIdentifier = state.a11yIdentifier

        // moreButton is always hidden; title button takes its role
        moreButton.isHidden = true

        titleBackgroundView.isHidden = !state.showsBlurBackground

        let color = textColor ?? theme.colors.textPrimary
        applyUnderlinedTitle(state.title, color: color)
        // Always apply theme so titleBackgroundView.backgroundColor is set on first configure
        // (applyTheme is not always called before configure on initial load).
        applyTheme(theme: theme)
    }

    // MARK: - Private helpers

    private func applyUnderlinedTitle(_ text: String?, color: UIColor) {
        guard let text else {
            titleButton.setAttributedTitle(nil, for: .normal)
            return
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: FXFontStyles.Bold.title3.scaledFont(),
            .foregroundColor: color
        ]
        titleButton.setAttributedTitle(NSAttributedString(string: text, attributes: attrs), for: .normal)
    }

    @objc private func handleTitleTap(_ sender: UIButton) {
        titleButtonAction?(sender)
    }

    // MARK: - Dynamic Type Support

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            // Re-apply title so font scales correctly
            applyUnderlinedTitle(title, color: titleButton.titleColor(for: .normal) ?? .label)
            setNeedsLayout()
            layoutIfNeeded()
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        applyUnderlinedTitle(title, color: theme.colors.textPrimary)
        titleBackgroundView.backgroundColor = .clear
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        ensureMainThread {
            switch notification.name {
            case UIContentSizeCategory.didChangeNotification:
                self.applyUnderlinedTitle(self.title, color: self.titleButton.titleColor(for: .normal) ?? .label)
                self.setNeedsLayout()
                self.layoutIfNeeded()
            default: break
            }
        }
    }
}
