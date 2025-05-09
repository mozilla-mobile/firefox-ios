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
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 4
    static let maxFontSize: CGFloat = 30
    static let horizontalInsets: CGFloat = 10
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
    private lazy var selectionBackgroundView: UIView = .build { _ in }
    private var selectionBackgroundLeadingConstraint: NSLayoutConstraint?
    private var selectionBackgroundTrailingConstraint: NSLayoutConstraint?

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
        selectionBackgroundView.backgroundColor = theme.colors.actionSecondary
        selectionBackgroundView.layer.cornerRadius = TabTraySelectorUX.cornerRadius
        addSubview(selectionBackgroundView)

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

            button.titleLabel?.font = index == selectedIndex ?
                FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize) :
                FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)

            button.accessibilityIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)"
            button.accessibilityHint = String(format: .TabsTray.TabTraySelectorAccessibilityHint,
                                              NSNumber(value: index + 1),
                                              NSNumber(value: items.count))
            button.translatesAutoresizingMaskIntoConstraints = false
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        applyTheme(theme: theme)
        setupInitialSelectionBackground()
    }

    private func setupInitialSelectionBackground() {
        guard buttons.indices.contains(selectedIndex) else { return }

        let selectedButton = buttons[selectedIndex]
        selectionBackgroundLeadingConstraint = selectionBackgroundView.leadingAnchor.constraint(
            equalTo: selectedButton.leadingAnchor, constant: -TabTraySelectorUX.horizontalInsets
        )
        selectionBackgroundTrailingConstraint = selectionBackgroundView.trailingAnchor.constraint(
            equalTo: selectedButton.trailingAnchor, constant: TabTraySelectorUX.horizontalInsets
        )

        NSLayoutConstraint.activate([
            selectionBackgroundView.topAnchor.constraint(equalTo: selectedButton.topAnchor,
                                                         constant: -TabTraySelectorUX.verticalInsets),
            selectionBackgroundView.bottomAnchor.constraint(equalTo: selectedButton.bottomAnchor,
                                                            constant: TabTraySelectorUX.verticalInsets),
            selectionBackgroundLeadingConstraint!,
            selectionBackgroundTrailingConstraint!
        ])
    }

    private func updateLabels() {
        for (index, title) in items.enumerated() {
            buttons[safe: index]?.setTitle(title, for: .normal)
        }
    }

    @objc
    private func sectionSelected(_ sender: UIButton) {
        selectedIndex = sender.tag
    }

    func select(index: Int) {
        guard index != selectedIndex, index >= 0, index < buttons.count else { return }
        selectedIndex = index
    }

    private func selectNewSection() {
        guard buttons.indices.contains(selectedIndex) else { return }

        let newSelectedButton = buttons[selectedIndex]
        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.titleLabel?.font = FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            } else {
                button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            }
        }

        selectionBackgroundLeadingConstraint?.isActive = false
        selectionBackgroundLeadingConstraint = selectionBackgroundView.leadingAnchor.constraint(
            equalTo: newSelectedButton.leadingAnchor, constant: -TabTraySelectorUX.horizontalInsets
        )
        selectionBackgroundLeadingConstraint?.isActive = true

        selectionBackgroundTrailingConstraint?.isActive = false
        selectionBackgroundTrailingConstraint = selectionBackgroundView.trailingAnchor.constraint(
            equalTo: newSelectedButton.trailingAnchor, constant: TabTraySelectorUX.horizontalInsets
        )
        selectionBackgroundTrailingConstraint?.isActive = true

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.layoutIfNeeded()
        }, completion: nil)

        let panelType = TabTrayPanelType.getExperimentConvert(index: selectedIndex)
        delegate?.didSelectSection(panelType: panelType)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.layer1
        selectionBackgroundView.backgroundColor = theme.colors.actionSecondary

        for button in buttons {
            button.setTitleColor(theme.colors.textPrimary, for: .normal)
        }
    }
}
