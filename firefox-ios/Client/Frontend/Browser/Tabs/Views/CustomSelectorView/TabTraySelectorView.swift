// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol TabTraySelectorDelegate: AnyObject {
    @MainActor
    func didSelectSection(panelType: TabTrayPanelType)
}

// MARK: - UX Constants
struct TabTraySelectorUX {
    static let horizontalSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 8
    static let horizontalInsets: CGFloat = 10
    static let fontScaleDelta: CGFloat = 0.055
    static let stackViewLeadingTrailingPadding: CGFloat = 8
    static let containerHorizontalSpacing: CGFloat = 16
    static let topSpacing: CGFloat = 8
    static let bottomSpacingIOS26: CGFloat = 16
}

class TabTraySelectorView: UIView,
                           ThemeApplicable,
                           FeatureFlaggable {
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int
    private var buttons: [TabTraySelectorButton] = []
    private var buttonTitles: [String]
    private var selectionBackgroundWidthConstraint: NSLayoutConstraint?
    private var stackViewOffsetConstraint: NSLayoutConstraint?
    private let edgeFadeGradientLayer = CAGradientLayer()

    private var tabTrayUtils: TabTrayUtils

    private lazy var containerView: UIView = .build { view in
        if #available(iOS 26, *) {
            view.clipsToBounds = true
        }
    }

    private lazy var selectionBackgroundView: UIView = .build { view in
        if #unavailable(iOS 26) {
            view.layer.cornerRadius = TabTraySelectorUX.cornerRadius
        }
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = TabTraySelectorUX.horizontalSpacing
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
        updateEdgeFadeMask()

        if #available(iOS 26, *) {
            selectionBackgroundView.layer.cornerRadius = selectionBackgroundView.frame.height / 2
            visualEffectView.layer.cornerRadius = containerView.frame.height / 2
        }
    }

    func updateSelectionProgress(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        updateSelectionBackground(from: fromIndex, to: toIndex, progress: abs(progress), animated: false)
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
        containerView.layer.mask = edgeFadeGradientLayer

        for (index, title) in buttonTitles.enumerated() {
            let button = createButton(with: index, title: title)
            buttons.append(button)
            stackView.addArrangedSubview(button)
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }

        let bottomSpacing: CGFloat = if #available(iOS 26.0, *) {
            -TabTraySelectorUX.bottomSpacingIOS26
        } else {
            0
        }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor,
                                               constant: TabTraySelectorUX.topSpacing),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomSpacing),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: TabTraySelectorUX.containerHorizontalSpacing),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                    constant: -TabTraySelectorUX.containerHorizontalSpacing),

            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            selectionBackgroundView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            selectionBackgroundView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            selectionBackgroundView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])

        if #available(iOS 26, *) {
            NSLayoutConstraint.activate([
                visualEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }

        applyInitialConstraints()
        addSwipeGestureRecognizer(direction: .right)
        addSwipeGestureRecognizer(direction: .left)
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
            top: TabTraySelectorUX.verticalInsets,
            leading: TabTraySelectorUX.horizontalInsets,
            bottom: TabTraySelectorUX.verticalInsets,
            trailing: TabTraySelectorUX.horizontalInsets
        )
        let viewModel = TabTraySelectorButtonModel(
            title: title,
            a11yIdentifier: "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)",
            a11yHint: hint,
            font: font,
            contentInsets: contentInsets,
            cornerRadius: TabTraySelectorUX.cornerRadius
        )
        button.configure(viewModel: viewModel)
        button.applyTheme(theme: theme)

        button.tag = index
        button.addTarget(self, action: #selector(sectionSelected(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func applyInitialConstraints() {
        guard buttons.indices.contains(selectedIndex) else { return }
        layoutIfNeeded()

        // Ensure the selected background has proper width
        let selectedButton = buttons[selectedIndex]
        selectionBackgroundWidthConstraint = selectionBackgroundView.widthAnchor.constraint(
            equalToConstant: selectedButton.frame.width
        )
        selectionBackgroundWidthConstraint?.isActive = true

        // Ensure the stack view is positioned so the selected button is centered
        let buttonCenter = selectedButton.convert(selectedButton.bounds.center, to: containerView)
        let offset = stackView.frame.midX - buttonCenter.x
        stackViewOffsetConstraint = stackView.centerXAnchor.constraint(
            equalTo: containerView.centerXAnchor, constant: offset
        )
        stackViewOffsetConstraint?.isActive = true
    }

    /// Calculates and applies a fixed width constraint to a button based on the maximum
    /// width required by its title when rendered in both regular and bold font styles.
    ///
    /// This prevents visual layout shifts during font weight transitions (e.g., from regular to bold),
    /// ensuring consistent spacing and avoiding jitter in horizontally stacked button layouts.
    private func applyButtonWidthAnchor(on button: UIButton, with title: NSString) {
        if let existingConstraint = button.constraints.first(where: { $0.firstAttribute == .width }) {
            existingConstraint.isActive = false
        }

        let boldFont = FXFontStyles.Bold.body.systemFont()
        let boldWidth = ceil(title.size(withAttributes: [.font: boldFont]).width)
        let horizontalInsets = TabTraySelectorUX.horizontalInsets * 2
        button.widthAnchor.constraint(equalToConstant: boldWidth + horizontalInsets).isActive = true
    }

    // MARK: - Gesture Recognizers
    private func addSwipeGestureRecognizer(direction: UISwipeGestureRecognizer.Direction) {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        gestureRecognizer.direction = direction
        addGestureRecognizer(gestureRecognizer)
    }

    @objc
    private func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .left:
            let index = selectedIndex + 1
            if buttons.indices.contains(index) {
                sectionSelected(buttons[index])
            }
        case .right:
            let index = selectedIndex - 1
            if buttons.indices.contains(index) {
                sectionSelected(buttons[index])
            }
        default:
            break
        }
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

        animateStackViewToCenterSelectedButton()
        animateSelectionBackground(to: sender)
        adjustSelectedButtonFont(toIndex: toIndex)

        let panelType = TabTrayPanelType.getExperimentConvert(index: toIndex)
        delegate?.didSelectSection(panelType: panelType)
    }

    private func animateStackViewToCenterSelectedButton() {
        let selectedButton = buttons[selectedIndex]
        stackViewOffsetConstraint?.isActive = false
        stackViewOffsetConstraint = selectionBackgroundView.centerXAnchor.constraint(
            equalTo: selectedButton.centerXAnchor
        )
        stackViewOffsetConstraint?.isActive = true

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.layoutIfNeeded()
        })
    }

    private func animateSelectionBackground(to button: UIButton) {
        selectionBackgroundWidthConstraint?.constant = button.frame.width

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            self.layoutIfNeeded()
        })
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
                // Scale down as we move away
                let scale = 1.0 - TabTraySelectorUX.fontScaleDelta * easedProgress
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else if index == toIndex {
                // Scale up as we approach
                let scale = 1.0 + TabTraySelectorUX.fontScaleDelta * easedProgress
                button.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else {
                // Reset others
                button.transform = .identity
            }
        }
    }

    /// Updates or animates the selection background's position and width based on transition progress.
    ///
    /// - Parameters:
    ///   - fromIndex: Index of the previously selected button.
    ///   - toIndex: Index of the target button.
    ///   - progress: Value between 0.0 and 1.0 indicating how far the transition is.
    ///               Use 1.0 for a completed transition.
    ///   - animated: Whether to animate the update (used when a selection is finalized).
    private func updateSelectionBackground(from fromIndex: Int,
                                           to toIndex: Int,
                                           progress: CGFloat,
                                           animated: Bool) {
        guard buttons.indices.contains(fromIndex), buttons.indices.contains(toIndex) else { return }

        let fromButton = buttons[fromIndex]
        let toButton = buttons[toIndex]

        let fromCenter = fromButton.convert(fromButton.bounds.center, to: containerView)
        let toCenter = toButton.convert(toButton.bounds.center, to: containerView)
        let interpolatedX = fromCenter.x + (toCenter.x - fromCenter.x) * progress
        let offset = stackView.frame.midX - interpolatedX

        stackViewOffsetConstraint?.isActive = false
        stackViewOffsetConstraint = stackView.centerXAnchor.constraint(
            equalTo: containerView.centerXAnchor, constant: offset
        )
        stackViewOffsetConstraint?.isActive = true

        let fromWidth = fromButton.bounds.width
        let toWidth = toButton.bounds.width
        let interpolatedWidth = fromWidth + (toWidth - fromWidth) * progress
        selectionBackgroundWidthConstraint?.constant = interpolatedWidth

        layoutIfNeeded()
    }

    private func updateEdgeFadeMask() {
        edgeFadeGradientLayer.frame = containerView.bounds
        edgeFadeGradientLayer.colors = [UIColor.clear.cgColor,
                                        UIColor.black.cgColor,
                                        UIColor.black.cgColor,
                                        UIColor.clear.cgColor]
        edgeFadeGradientLayer.locations = [0.0, 0.05, 0.95, 1.0]
        edgeFadeGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        edgeFadeGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
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
