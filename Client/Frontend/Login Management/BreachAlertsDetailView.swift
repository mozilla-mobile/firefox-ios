/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

class BreachAlertsDetailView: UIView {

    private let textColor = UIColor.white

    lazy var titleIcon: UIImageView = {
        let image = UIImage(named: "Breached Website@3x")
        return UIImageView(image: image)
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = DynamicFontHelper.defaultHelper.DeviceFontLarge
        label.textColor = textColor
        label.text = Strings.BreachAlertsTitle
        return label
    }()

    lazy var titleLearnMore: UIButton = {
        let button = UIButton(type: .detailDisclosure)
        button.titleLabel?.text = Strings.BreachAlertsLearnMore
        button.titleLabel?.textColor = textColor
        return button
    }()

    lazy var titleContainer: UIStackView = {
        let container = UIStackView(arrangedSubviews: [titleIcon, titleLabel, titleLearnMore])
        container.axis = .horizontal
        return container
    }()

    lazy var breachDateLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsBreachDate
        label.textColor = textColor
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.BreachAlertsDescription
        label.textColor = textColor
        return label
    }()

    lazy var goToButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.text = Strings.BreachAlertsLink
        button.titleLabel?.textColor = textColor
        return button
    }()

    lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleContainer, breachDateLabel, descriptionLabel, goToButton])
        stack.axis = .vertical
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.red
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200)
        }

        self.addSubview(contentStack)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal override func updateConstraints() {
        super.updateConstraints()

//        contentStack.snp.remakeConstraints { make in
//            make.edges.equalToSuperview()
//        }
    }
}
