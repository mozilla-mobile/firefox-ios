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
    static let horizontalSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 8
    static let horizontalInsets: CGFloat = 10
    static let fontScaleDelta: CGFloat = 0.055
    static let stackViewLeadingTrailingPadding: CGFloat = 8
}

/// Represents the visual state of the selection indicator during a transition.
private struct SelectionIndicatorTransition {
    let selectionIndicatorWidthDuringTransition: CGFloat
    let targetOffset: CGFloat
}

class TabTraySelectorView: UIView,
                           ThemeApplicable,
                           Notifiable {
    var notificationCenter: NotificationProtocol
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int
    private var buttons: [TabTraySelectorButton] = []
    private var buttonTitles: [String]
    private var selectionBackgroundWidthConstraint: NSLayoutConstraint?

    private lazy var selectionBackgroundView: UIView = .build { _ in }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = TabTraySelectorUX.horizontalSpacing
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
    }

    init(selectedIndex: Int,
         theme: Theme,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         buttonTitles: [String]) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        self.notificationCenter = notificationCenter
        self.buttonTitles = buttonTitles
        super.init(frame: .zero)
        setupNotifications(forObserver: self, observing: [UIContentSizeCategory.didChangeNotification])
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        selectionBackgroundView.backgroundColor = theme.colors.actionSecondary
        selectionBackgroundView.layer.cornerRadius = TabTraySelectorUX.cornerRadius
        addSubview(selectionBackgroundView)
        addSubview(stackView)

        for (index, title) in buttonTitles.enumerated() {
            let button = createButton(with: index, title: title)
            buttons.append(button)
            stackView.addArrangedSubview(button)
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }

        applyInitalSelectionBackgroundFrame()

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                               constant: TabTraySelectorUX.stackViewLeadingTrailingPadding),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                                constant: -TabTraySelectorUX.stackViewLeadingTrailingPadding),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectionBackgroundView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            selectionBackgroundView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            selectionBackgroundView.centerXAnchor.constraint(equalTo: buttons[selectedIndex].centerXAnchor)
        ])

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

    private func applyInitalSelectionBackgroundFrame() {
        guard buttons.indices.contains(selectedIndex) else { return }
        layoutIfNeeded()
        let selectedButton = buttons[selectedIndex]
        let width = selectedButton.frame.width

        selectionBackgroundWidthConstraint?.isActive = false
        selectionBackgroundWidthConstraint = selectionBackgroundView.widthAnchor.constraint(equalToConstant: width)
        selectionBackgroundWidthConstraint?.isActive = true
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

    @objc
    private func sectionSelected(_ sender: UIButton) {
        let oldValue = selectedIndex
        selectedIndex = sender.tag
        selectNewSection(from: oldValue, to: selectedIndex)
    }

    private func selectNewSection(from fromIndex: Int, to toIndex: Int) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        adjustSelectedButtonFont(toIndex: toIndex)
        updateSelectionBackground(from: fromIndex, to: toIndex, progress: 1.0, animated: true)

        let panelType = TabTrayPanelType.getExperimentConvert(index: toIndex)
        delegate?.didSelectSection(panelType: panelType)
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
        guard let result = calculateSelectionTransition(from: fromIndex, to: toIndex, progress: progress) else {
            return
        }

        selectionBackgroundWidthConstraint?.constant = result.selectionIndicatorWidthDuringTransition
        let transform = CGAffineTransform(translationX: result.targetOffset, y: 0)
        let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled

        if shouldAnimate {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: {
                self.selectionBackgroundView.transform = transform
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
            selectionBackgroundView.transform = transform
            layoutIfNeeded()
        }
    }

    /// Calculates the horizontal offset and width for the selection background during a transition between two buttons.
    ///
    /// This is used to animate or update the selection pill's position and size as the user
    /// swipes or taps between different segments.
    ///
    /// - Parameters:
    ///   - fromIndex: The index of the starting button (currently selected).
    ///   - toIndex: The index of the target button (being selected).
    ///   - progress: A CGFloat between 0.0 and 1.0 representing the progress of the transition.
    ///               Uses 0 for the start position and 1 for the final position.
    ///
    /// - Returns: A `SelectionIndicatorTransition` containing the calculated width and offset
    private func calculateSelectionTransition(from fromIndex: Int,
                                              to toIndex: Int,
                                              progress: CGFloat) -> SelectionIndicatorTransition? {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex),
              let parentView = buttons[fromIndex].superview else { return nil }

        let fromButton = buttons[fromIndex]
        let toButton = buttons[toIndex]

        let fromX = fromButton.center.x
        let toX = toButton.center.x
        let buttonCenterXDuringTransition = fromX + (toX - fromX) * progress
        let selectionTargetCenterX = parentView.convert(CGPoint(x: buttonCenterXDuringTransition, y: 0), to: self).x
        let targetOffset = selectionTargetCenterX - selectionBackgroundView.center.x

        let fromWidth = fromButton.frame.width
        let toWidth = toButton.frame.width
        let selectionIndicatorWidthDuringTransition = fromWidth + (toWidth - fromWidth) * progress

        return SelectionIndicatorTransition(selectionIndicatorWidthDuringTransition: selectionIndicatorWidthDuringTransition,
                                            targetOffset: targetOffset)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.layer1
        selectionBackgroundView.backgroundColor = theme.colors.layer3

        for button in buttons {
            button.applyTheme(theme: theme)
        }
    }

    // MARK: - Notifiable

    public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            dynamicTypeChanged()
        default:
            break
        }
    }

    private func dynamicTypeChanged() {
        adjustSelectedButtonFont(toIndex: selectedIndex)

        for (index, title) in buttonTitles.enumerated() {
            guard let button = buttons[safe: index] else { continue }
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }

        applyInitalSelectionBackgroundFrame()
        updateSelectionBackground(from: selectedIndex,
                                  to: selectedIndex,
                                  progress: 1.0,
                                  animated: false)

        setNeedsLayout()
        layoutIfNeeded()
    }
}
