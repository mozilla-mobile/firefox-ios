// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class WelcomeTourProfit: UIView, ThemeApplicable {
    struct UX {
        static let offsetY: CGFloat = 50
    }

    private lazy var beforeView: BeforeOrAfterView = {
        let view = BeforeOrAfterView(type: .before)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var afterView: BeforeOrAfterView = {
        let view = BeforeOrAfterView(type: .after)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setup()
        updateAccessibilitySettings()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        addSubview(beforeView)
        addSubview(afterView)

        NSLayoutConstraint.activate([
            beforeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            beforeView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -UX.offsetY),
            afterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            afterView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: UX.offsetY)
        ])
    }

    func applyTheme(theme: Theme) {
        beforeView.applyTheme(theme: theme)
        afterView.applyTheme(theme: theme)
    }

    func updateAccessibilitySettings() {
        isAccessibilityElement = false
        shouldGroupAccessibilityChildren = true
    }
}
