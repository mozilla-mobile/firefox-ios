// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class TabTrayiPadSelectorView: UIView, ThemeApplicable {
    // MARK: - UX Constants
    struct UX {
        static let horizontalSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let verticalInsets: CGFloat = 8
        static let horizontalInsets: CGFloat = 10
        static let fontScaleDelta: CGFloat = 0.055
        static let containerHorizontalSpacing: CGFloat = 16
        static let stackViewHorizontalSpacing: CGFloat = 80
        static let topSpacing: CGFloat = 8
        static let bottomSpacingIOS26: CGFloat = 16
    }

    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int
    private var buttons: [TabTraySelectorButton] = []
    private var buttonTitles: [String]
    private var selectionBackgroundConstraints: [NSLayoutConstraint] = []

    private var tabTrayUtils: TabTrayUtils

    private lazy var containerView: UIView = .build { view in
        if #available(iOS 26, *) {
            view.clipsToBounds = true
        }
    }

    private lazy var selectionBackgroundView: UIView = .build { view in
        view.clipsToBounds = true
        view.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.iPadSelectionBackgroundView
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.horizontalSpacing
        stackView.distribution = .fill
        stackView.alignment = .center
    }

    private lazy var visualEffectView: UIVisualEffectView = .build { view in
#if canImport(FoundationModels)
        if #available(iOS 26, *), !DeviceInfo.isRunningLiquidGlassEarlyBeta {
            view.effect = UIGlassEffect(style: .regular)
        } else {
            view.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
#else
        view.effect = UIBlurEffect(style: .systemUltraThinMaterial)
#endif
    }

    init(selectedIndex: Int,
         theme: Theme,
         buttonTitles: [String],
         tabTrayUtils: TabTrayUtils = DefaultTabTrayUtils()) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        self.buttonTitles = buttonTitles
        self.tabTrayUtils = tabTrayUtils
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        selectionBackgroundView.layer.cornerRadius = containerView.bounds.height / 2
        if #available(iOS 26, *) {
            visualEffectView.layer.cornerRadius = containerView.bounds.height / 2
        }
    }

    func updateSelectionProgress(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        updateSelectionBackground()
        simulateFontWeightTransition(from: fromIndex, to: toIndex, progress: abs(progress))
    }

    func didFinishSelection(to index: Int) {
        selectedIndex = index
        adjustSelectedButtonFont(toIndex: index)
    }

    private func setup() {
        if #available(iOS 26, *) {
            addSubview(visualEffectView)
        }
        addSubview(containerView)
        containerView.addSubview(selectionBackgroundView)
        containerView.addSubview(stackView)
        containerView.sendSubviewToBack(selectionBackgroundView)

        for (index, title) in buttonTitles.enumerated() {
            let button = createButton(with: index, title: title)
            buttons.append(button)
            stackView.addArrangedSubview(button)
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topSpacing),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.bottomSpacingIOS26),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: UX.containerHorizontalSpacing),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                    constant: -UX.containerHorizontalSpacing),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                               constant: UX.stackViewHorizontalSpacing),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                constant: -UX.stackViewHorizontalSpacing),
        ])

        if #available(iOS 26, *) {
            NSLayoutConstraint.activate([
                visualEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }

        updateSelectionBackground()
        applyTheme(theme: theme)
    }

    private func createButton(with index: Int, title: String) -> TabTraySelectorButton {
        let button = TabTraySelectorButton()
        let hint = String(format: .TabsTray.TabTraySelectorAccessibilityHint,
                          NSNumber(value: index + 1),
                          NSNumber(value: buttonTitles.count))
        let font = index == selectedIndex
            ? FXFontStyles.Bold.body.systemFont()
            : FXFontStyles.Regular.body.systemFont()
        let contentInsets = NSDirectionalEdgeInsets(
            top: UX.verticalInsets,
            leading: UX.horizontalInsets,
            bottom: UX.verticalInsets,
            trailing: UX.horizontalInsets
        )
        let viewModel = TabTraySelectorButtonModel(
            title: title,
            a11yIdentifier: "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)",
            a11yHint: hint,
            font: font,
            contentInsets: contentInsets,
            cornerRadius: UX.cornerRadius
        )
        button.configure(viewModel: viewModel)
        button.applyTheme(theme: theme)

        button.tag = index
        button.addTarget(self, action: #selector(sectionSelected(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func updateSelectionBackground() {
        guard buttons.indices.contains(selectedIndex) else { return }

        let selectedButton = buttons[selectedIndex]

        NSLayoutConstraint.deactivate(selectionBackgroundConstraints)

        selectionBackgroundConstraints = [
            selectionBackgroundView.topAnchor.constraint(equalTo: selectedButton.topAnchor),
            selectionBackgroundView.leadingAnchor.constraint(equalTo: selectedButton.leadingAnchor),
            selectionBackgroundView.bottomAnchor.constraint(equalTo: selectedButton.bottomAnchor),
            selectionBackgroundView.trailingAnchor.constraint(equalTo: selectedButton.trailingAnchor)
        ]

        NSLayoutConstraint.activate(selectionBackgroundConstraints)
    }

    private func applyButtonWidthAnchor(on button: UIButton, with title: NSString) {
        let boldFont = FXFontStyles.Bold.body.systemFont()
        let boldWidth = ceil(title.size(withAttributes: [.font: boldFont]).width)
        let horizontalInsets = UX.horizontalInsets * 2
        button.widthAnchor.constraint(equalToConstant: boldWidth + horizontalInsets).isActive = true
    }

    @objc
    private func sectionSelected(_ sender: UIButton) {
        let oldValue = selectedIndex
        selectedIndex = sender.tag
        selectNewSection(from: oldValue, to: selectedIndex, sender: sender)
    }

    private func selectNewSection(from fromIndex: Int, to toIndex: Int, sender: UIButton) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        animateSelectionBackground(to: sender)
        adjustSelectedButtonFont(toIndex: toIndex)

        let panelType = TabTrayPanelType.getExperimentConvert(index: toIndex)
        delegate?.didSelectSection(panelType: panelType)
    }

    private func animateSelectionBackground(to button: UIButton) {
        updateSelectionBackground()

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }
    }

    private func adjustSelectedButtonFont(toIndex: Int) {
        for (index, button) in buttons.enumerated() {
            button.transform = .identity
            let isSelected = index == toIndex
            button.isSelected = isSelected

            let font = isSelected
                ? FXFontStyles.Bold.body.systemFont()
                : FXFontStyles.Regular.body.systemFont()
            button.applySelectedFontChange(font: font)
        }
    }

    private func simulateFontWeightTransition(from fromIndex: Int, to toIndex: Int, progress: CGFloat) {
        guard buttons.indices.contains(fromIndex), buttons.indices.contains(toIndex) else { return }

        let easedProgress = 1 - pow(1 - progress, 2)
        for (index, button) in buttons.enumerated() {
            if index == fromIndex {
                let scale = 1.0 - UX.fontScaleDelta * easedProgress
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else if index == toIndex {
                let scale = 1.0 + UX.fontScaleDelta * easedProgress
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else {
                button.transform = .identity
            }
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme

        if #unavailable(iOS 26) {
            let backgroundAlpha: CGFloat = tabTrayUtils.backgroundAlpha()
            backgroundColor = theme.colors.layer1.withAlphaComponent(backgroundAlpha)
        }

        selectionBackgroundView.backgroundColor = theme.colors.layerEmphasis

        for button in buttons {
            button.applyTheme(theme: theme)
        }
    }
}
