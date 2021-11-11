// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// MARK: - Section Header View
public struct FirefoxHomeHeaderViewUX {
    static let insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeUX.sectionInsetsForIpad + FirefoxHomeUX.minimumInsets : FirefoxHomeUX.minimumInsets
    static let titleTopInset: CGFloat = 5
    static let sectionHeaderSize: CGFloat = 20
    static let maxTitleLabelTextSize: CGFloat = 55 // Style title3 - AX5
    static let maxMoreButtonTextSize: CGFloat = 49 // Style subheadline - AX5
}

enum ASHeaderViewType {
    case otherGroupTabs
    case normal
}

// Activity Stream header view
class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 4
    var sectionType: ASHeaderViewType = .normal
    private var titleLeadingConstraint: NSLayoutConstraint?

    lazy var titleLabel: UILabel = .build { label in
        label.text = self.title
        label.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       maxSize: FirefoxHomeHeaderViewUX.maxTitleLabelTextSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    lazy var moreButton: UIButton = .build { button in
        button.isHidden = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                                maxSize: FirefoxHomeHeaderViewUX.maxMoreButtonTextSize)
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
    }

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.insets : FirefoxHomeUX.minimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)

        NSLayoutConstraint.activate([
            moreButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            moreButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -titleInsets),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -FirefoxHomeHeaderViewUX.titleTopInset),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)

        titleLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: titleInsets)
        titleLeadingConstraint?.isActive = true
    }

    func remakeConstraint(type: ASHeaderViewType) {
        let inset = type == .otherGroupTabs ? 15 : titleInsets
        titleLeadingConstraint?.constant = inset
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
