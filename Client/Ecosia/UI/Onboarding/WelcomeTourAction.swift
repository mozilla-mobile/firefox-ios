/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class WelcomeTourAction: UIView, NotificationThemeable {

    private weak var stack: UIStackView!

    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .leading
        stack.spacing = 8
        addSubview(stack)
        self.stack = stack

        stack.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: 54).isActive = true
        let height = heightAnchor.constraint(equalToConstant: 200)
        height.priority = .init(rawValue: 500)
        height.isActive = true

        let trees = TreeCounter.shared.statistics.treesAt(.init())
        let oneMillion = 1000000
        let millionTrees = trees / oneMillion
        let multiplesOfFive = millionTrees / 5
        let capped = multiplesOfFive * 5 * oneMillion
        let count = formatter.string(from: .init(value: capped)) ?? "150M"

        let top = WelcomeTourActionRow(image: "trees", title: "\(count)+", text: .localized(.treesPlantedByTheCommunity))
        stack.addArrangedSubview(top)

        let middle = WelcomeTourActionRow(image: "hand", title: "60+", text: .localized(.activeProjects))
        stack.addArrangedSubview(middle)

        let bottom = WelcomeTourActionRow(image: "pins", title: "30+", text: .localized(.countries))
        stack.addArrangedSubview(bottom)
    }

    func applyTheme() {
        stack.arrangedSubviews.forEach { view in
            (view as? NotificationThemeable)?.applyTheme()
        }
    }
}

final class WelcomeTourActionRow: UIView, NotificationThemeable {
    let image: String
    let title: String
    let text: String

    weak var titleLabel: UILabel!
    weak var textLabel: UILabel!

    init(image: String, title: String, text: String) {
        self.image = image
        self.title = title
        self.text = text

        super.init(frame: .zero)
        setup()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        layer.cornerRadius = 10

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .leading
        stack.spacing = 4
        addSubview(stack)

        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

        let topStack = UIStackView()
        topStack.spacing = 8
        topStack.axis = .horizontal
        topStack.alignment = .center

        stack.addArrangedSubview(topStack)

        let imageView = UIImageView(image: .init(named: image))
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        topStack.addArrangedSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body).bold()
        titleLabel.adjustsFontForContentSizeCategory = true
        topStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .preferredFont(forTextStyle: .footnote)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(textLabel)
        self.textLabel = textLabel
    }

    func applyTheme() {
        backgroundColor = .theme.ecosia.welcomeElementBackground
        titleLabel.textColor = .theme.ecosia.primaryText
        textLabel.textColor = .theme.ecosia.secondaryText
    }
}
