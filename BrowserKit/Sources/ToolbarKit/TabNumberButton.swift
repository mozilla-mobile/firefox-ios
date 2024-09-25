// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class TabNumberButton: ToolbarButton {
    // MARK: - UX Constants
    struct UX {
        static let cornerRadius: CGFloat = 2
        static let titleFont = FXFontStyles.Bold.caption2.systemFont()

        // Tab count related constants
        static let defaultCountLabelText = "0"
        static let maxTabCount = 99
        static let infinitySymbol = "\u{221E}"
    }

    // MARK: - Properties
    private lazy var countLabel: UILabel = .build { label in
        label.text = UX.defaultCountLabelText
        label.font = UX.titleFont
        label.layer.cornerRadius = UX.cornerRadius
        label.textAlignment = .center
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func configure(element: ToolbarElement) {
        super.configure(element: element)

        guard let numberOfTabs = element.numberOfTabs else { return }
        updateTabCount(numberOfTabs)
    }

    override public func updateConfiguration() {
        super.updateConfiguration()

        // Use image view tint color for tab number label as it gets dimmed when a modal gets displayed
        countLabel.textColor = imageView?.tintColor ?? configuration?.baseForegroundColor
    }

    private func updateTabCount(_ count: Int) {
        let count = max(count, 1)
        let countToBe = (count <= UX.maxTabCount) ? count.description : UX.infinitySymbol
        countLabel.text = countToBe
        accessibilityValue = countToBe
    }

    // MARK: - Layout
    private func setupLayout() {
        addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: topAnchor),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
