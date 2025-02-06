// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia
import Common

final class WelcomeTourAction: UIView, ThemeApplicable {

    // MARK: - Properties

    private weak var stack: UIStackView!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        updateAccessibilitySettings()
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

        let trees = TreesProjection.shared.treesAt(.init())
        let oneMillion = 1000000
        let millionTrees = trees / oneMillion
        let multiplesOfFive = millionTrees / 5
        let capped = multiplesOfFive * 5 * oneMillion
        let treesPlantedByTheCommunity = NumberFormatter.ecosiaDecimalNumberFormatter().string(from: .init(value: capped)) ?? "150M"
        let countries = "30"
        let activeProjects = "60"

        let top = WelcomeTourRow(image: "trees",
                                 title: .init(format: .localized(.numberAsStringWithPlusSymbol), treesPlantedByTheCommunity),
                                 text: .localized(.treesPlantedByEcosiaCapitalized))
        stack.addArrangedSubview(top)

        let middle = WelcomeTourRow(image: "hand",
                                    title: .init(format: .localized(.numberAsStringWithPlusSymbol), activeProjects),
                                    text: .localized(.activeProjects))
        stack.addArrangedSubview(middle)

        let bottom = WelcomeTourRow(image: "pins",
                                    title: .init(format: .localized(.numberAsStringWithPlusSymbol), countries),
                                    text: .localized(.countries))
        stack.addArrangedSubview(bottom)
    }

    func applyTheme(theme: Theme) {
        stack.arrangedSubviews.forEach { view in
            (view as? ThemeApplicable)?.applyTheme(theme: theme)
        }
    }

    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}
