// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary
import Shared

struct LabelButtonHeaderViewModel {
    var leadingInset: CGFloat = 0
    var title: String?
    var titleA11yIdentifier: String?
    var isButtonHidden: Bool
    var buttonTitle: String?
    var buttonAction: ((UIButton) -> Void)?
    var buttonA11yIdentifier: String?
    var textColor: UIColor?

    static var emptyHeader: LabelButtonHeaderViewModel {
        return LabelButtonHeaderViewModel(title: nil, isButtonHidden: true)
    }
}

// Firefox home view controller header view
class LegacyLabelButtonHeaderView: UICollectionReusableView, ReusableCell {
    struct UX {
        static let inBetweenSpace: CGFloat = 12
        static let bottomSpace: CGFloat = 10
        static let bottomButtonSpace: CGFloat = 6
        static let leadingInset: CGFloat = 0
        static let trailingInset: CGFloat = HomepageViewModel.UX.standardInset
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
    }

    private lazy var moreButton: ActionButton = .build { button in
        button.isHidden = true
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    private var viewModel: LabelButtonHeaderViewModel?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var stackViewLeadingConstraint: NSLayoutConstraint!

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
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackViewLeadingConstraint,
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                constant: -UX.trailingInset),
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

    func configure(viewModel: LabelButtonHeaderViewModel, theme: Theme) {
        self.viewModel = viewModel

        title = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yIdentifier

        moreButton.isHidden = viewModel.isButtonHidden
        if !viewModel.isButtonHidden {
            let moreButtonViewModel = ActionButtonViewModel(title: .BookmarksSavedShowAllText,
                                                            a11yIdentifier: viewModel.buttonA11yIdentifier,
                                                            touchUpAction: viewModel.buttonAction)
            moreButton.configure(viewModel: moreButtonViewModel)
        }

        // Update constant value for `TabDisplayManager` usage that is not using Section inset
        stackViewLeadingConstraint?.constant = viewModel.leadingInset
        applyTheme(theme: theme)
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
}

// MARK: - Theme
extension LegacyLabelButtonHeaderView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        let titleColor = viewModel?.textColor ?? theme.colors.textPrimary
        let moreButtonColor = viewModel?.textColor ?? theme.colors.textAccent

        titleLabel.textColor = titleColor
        moreButton.foregroundColorNormal = moreButtonColor
    }
}

// MARK: - Notifiable
extension LegacyLabelButtonHeaderView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}
