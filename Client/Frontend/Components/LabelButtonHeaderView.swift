// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

struct LabelButtonHeaderViewModel {
    var leadingInset: CGFloat = 0
    var trailingInset: CGFloat = HomepageViewModel.UX.standardInset
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
class LabelButtonHeaderView: UICollectionReusableView, ReusableCell {

    struct UX {
        static let titleLabelTextSize: CGFloat = 20
        static let moreButtonTextSize: CGFloat = 15
        static let inBetweenSpace: CGFloat = 12
        static let bottomSpace: CGFloat = 10
        static let bottomButtonSpace: CGFloat = 6
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
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.titleLabelTextSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var moreButton: ActionButton = .build { button in
        button.isHidden = true
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                size: UX.moreButtonTextSize)
        button.contentHorizontalAlignment = .trailing
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    private var viewModel: LabelButtonHeaderViewModel?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(moreButton)
        addSubview(stackView)

        applyTheme()
        adjustLayout()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged, .DynamicFontChanged])
    }

    func setConstraints(viewModel: LabelButtonHeaderViewModel) {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                               constant: viewModel.leadingInset),
            stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                constant: -viewModel.trailingInset),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpace),
        ])

        moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
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

    func configure(viewModel: LabelButtonHeaderViewModel) {
        self.viewModel = viewModel

        title = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yIdentifier

        moreButton.isHidden = viewModel.isButtonHidden
        if !viewModel.isButtonHidden {
            moreButton.setTitle(.RecentlySavedShowAllText, for: .normal)
            moreButton.touchUpAction = viewModel.buttonAction
            moreButton.accessibilityIdentifier = viewModel.buttonA11yIdentifier
        }

        setConstraints(viewModel: viewModel)
        applyTheme()
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
    }
}

// MARK: - Theme
extension LabelButtonHeaderView: NotificationThemeable {
    func applyTheme() {
        let textColor = viewModel?.textColor ?? LegacyThemeManager.instance.current.homePanel.topSiteHeaderTitle

        titleLabel.textColor = textColor
        moreButton.setTitleColor(textColor, for: .normal)
    }
}

// MARK: - Notifiable
extension LabelButtonHeaderView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}
