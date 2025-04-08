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
        static let bottomSpace: CGFloat = 10
        static let bottomButtonSpace: CGFloat = 6
        static let leadingInset: CGFloat = 0
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
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private var stackViewLeadingConstraint: NSLayoutConstraint?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(moreButton)
        addSubview(stackView)

        setupLayout()
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
    }

    private func setupLayout() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(moreButton)
        addSubview(stackView)

        stackViewLeadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                        constant: UX.leadingInset)
        stackViewLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpace),
        ])

        // Setting custom values to resolve horizontal ambiguity
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        titleLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)

        adjustLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Helper functions
    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    func configure(
        state: SectionHeaderConfiguration,
        moreButtonAction: ((UIButton) -> Void)? = nil,
        textColor: UIColor?,
        theme: Theme
    ) {
        self.title = state.title
        titleLabel.accessibilityIdentifier = state.a11yIdentifier

        moreButton.isHidden = state.isButtonHidden
        if !state.isButtonHidden {
            let moreButtonViewModel = ActionButtonViewModel(
                title: .BookmarksSavedShowAllText,
                a11yIdentifier: state.buttonA11yIdentifier,
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
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}
