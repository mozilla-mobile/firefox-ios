// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

struct ASHeaderViewModel {
    var inset: CGFloat = FirefoxHomeViewModel.UX.standardLeadingInset
    var title: String?
    var titleA11yIdentifier: String?
    var isButtonHidden: Bool
    var buttonTitle: String?
    var buttonAction: ((UIButton) -> Void)?
    var buttonA11yIdentifier: String?

    static var emptyHeader: ASHeaderViewModel {
        return ASHeaderViewModel(title: nil,
                                 isButtonHidden: true)
    }
}

// Firefox home view controller header view
class ASHeaderView: UICollectionReusableView {

    struct UX {
        static let maxTitleLabelTextSize: CGFloat = 55 // Style title3 - AX5
        static let maxMoreButtonTextSize: CGFloat = 49 // Style subheadline - AX5
    }

    static var cellIdentifier: String = "CellIdentifier"

    // MARK: - UIElements
    lazy var titleLabel: UILabel = .build { label in
        label.text = self.title
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       maxSize: UX.maxTitleLabelTextSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    lazy var moreButton: ActionButton = .build { button in
        button.isHidden = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                maxSize: UX.maxMoreButtonTextSize)
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }

    // MARK: - Variables
    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    static let verticalInsets: CGFloat = 4
    private var viewModel: ASHeaderViewModel?
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)

        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
    }

    func setConstraints(viewModel: ASHeaderViewModel) {
        NSLayoutConstraint.activate([
            moreButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            moreButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -viewModel.inset),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: viewModel.inset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])

        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
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

    func configure(viewModel: ASHeaderViewModel) {
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
    }
}

// MARK: - Theme
extension ASHeaderView: NotificationThemeable {
    func applyTheme() {
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
    }
}

// MARK: - Notifiable
extension ASHeaderView: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
