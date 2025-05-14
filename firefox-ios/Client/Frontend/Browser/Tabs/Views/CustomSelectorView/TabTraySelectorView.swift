// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol TabTraySelectorDelegate: AnyObject {
    func didSelectSection(panelType: TabTrayPanelType)
}

// MARK: - UX Constants
struct TabTraySelectorUX {
    static let horizontalPadding: CGFloat = 40
    static let cellVerticalPadding: CGFloat = 8
    static let estimatedCellWidth: CGFloat = 100
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 4
    static let maxFontSize: CGFloat = 30
}

class TabTraySelectorView: UIView,
                           ThemeApplicable {
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int {
        didSet {
            if oldValue != selectedIndex {
                selectNewSection()
            }
        }
    }
    private var buttons: [UIButton] = []

    var items: [String] = ["", "", ""] {
        didSet {
            updateLabels()
        }
    }

    init(selectedIndex: Int,
         theme: Theme) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = TabTraySelectorUX.horizontalPadding
        stackView.distribution = .equalCentering
        stackView.alignment = .center

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        for (index, title) in items.enumerated() {
            let button = UIButton()
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(sectionSelected(_:)), for: .touchUpInside)

            buttons.append(button)
            stackView.addArrangedSubview(button)

            button.titleLabel?.font = index == selectedIndex ?
                FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize) :
                FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)

            button.accessibilityIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)"
            button.accessibilityHint = String(format: .TabsTray.TabTraySelectorAccessibilityHint,
                                              NSNumber(value: index + 1),
                                              NSNumber(value: items.count))
        }

        applyTheme(theme: theme)
    }

    private func updateLabels() {
        for (index, title) in items.enumerated() {
            buttons[index].setTitle(title, for: .normal)
        }
    }

    @objc
    private func sectionSelected(_ sender: UIButton) {
        selectedIndex = sender.tag
    }

    private func selectNewSection() {
        var panelType: TabTrayPanelType = .tabs
        if selectedIndex == 0 {
            panelType = .privateTabs
        } else if selectedIndex == 1 {
            panelType = .tabs
        } else if selectedIndex == 2 {
            panelType = .syncedTabs
        }

        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.titleLabel?.font = FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            } else {
                button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            }
        }

        delegate?.didSelectSection(panelType: panelType)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.layer1

        for button in buttons {
            button.setTitleColor(theme.colors.textPrimary, for: .normal)
        }
    }
}
