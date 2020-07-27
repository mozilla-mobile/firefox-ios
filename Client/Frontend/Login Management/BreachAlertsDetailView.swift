/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class BreachAlertsDetailView: UIView {

    private let textColor = UIColor.white
    private let titleIconSize: CGFloat = 24
    private lazy var titleIconContainerSize: CGFloat = {
        return titleIconSize+LoginTableViewCellUX.HorizontalMargin
    }()

    lazy var titleIcon: UIImageView = {
        let imageView = UIImageView(image: BreachAlertsManager.icon)
        imageView.tintColor = textColor
        return imageView
    }()

    lazy var titleIconContainer: UIView = {
        let container = UIView()
        container.addSubview(titleIcon)
        titleIcon.snp.makeConstraints { make in
            make.width.height.equalTo(titleIconSize)
            make.center.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.width.equalTo(titleIconContainerSize)
        }
        return container
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.DeviceFontLargeBold
        label.textColor = textColor
        label.text = Strings.BreachAlertsTitle
        label.sizeToFit()
        return label
    }()

    lazy var titleLearnMore: UIButton = {
        let button = UIButton()
        button.setTitle(Strings.BreachAlertsLearnMore, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.tintColor = .white
        return button
    }()

    lazy var titleStack: UIStackView = {
        let container = UIStackView(arrangedSubviews: [titleIconContainer, titleLabel, titleLearnMore])
        container.axis = .horizontal
        return container
    }()

    lazy var breachDateLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsBreachDate
        label.textColor = textColor
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsDescription
        label.numberOfLines = 0
        label.textColor = textColor
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmall
        return label
    }()

    lazy var goToButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        button.contentHorizontalAlignment = .left
        return button
    }()

    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [breachDateLabel, descriptionLabel, goToButton])
        stack.axis = .vertical
        return stack
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleStack, infoStack])
        stack.axis = .vertical
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = BreachAlertsManager.detailColor
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true

        self.addSubview(contentStack)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        titleStack.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }
        infoStack.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(titleIconContainerSize)
        }
        contentStack.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(LoginTableViewCellUX.HorizontalMargin)
        }
        self.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }
}
