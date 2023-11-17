/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Common

final class WelcomeTourAction: UIView, Themeable {

    private weak var stack: UIStackView!

    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

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
        let count = formatter.string(from: .init(value: capped)) ?? "150M"

        let top = WelcomeTourRow(image: "trees", title: "\(count)+", text: .localized(.treesPlantedByTheCommunityCapitalized))
        stack.addArrangedSubview(top)

        let middle = WelcomeTourRow(image: "hand", title: "60+", text: .localized(.activeProjects))
        stack.addArrangedSubview(middle)

        let bottom = WelcomeTourRow(image: "pins", title: "30+", text: .localized(.countries))
        stack.addArrangedSubview(bottom)
    }

    func applyTheme() {
        stack.arrangedSubviews.forEach { view in
            (view as? Themeable)?.applyTheme()
        }
    }
    
    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}
