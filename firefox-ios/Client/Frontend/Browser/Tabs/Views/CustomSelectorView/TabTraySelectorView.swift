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
    static let fontScaleDelta: CGFloat = 0.055
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
    private var buttons: [UIButton] = []
    private lazy var selectionBackgroundView: UIView = .build { _ in }
    private var selectionBackgroundWidthConstraint: NSLayoutConstraint?

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = TabTraySelectorUX.horizontalPadding
        stackView.distribution = .equalCentering
        stackView.alignment = .center
    }

    var items: [String] = ["", "", ""] {
        didSet {
            updateLabels()
            // We need the labels on the buttons to adjust proper frame size
            applyInitalSelectionBackgroundFrame()
        }
    }

    init(selectedIndex: Int,
         theme: Theme,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        self.notificationCenter = notificationCenter
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

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectionBackgroundView.heightAnchor.constraint(equalTo: stackView.heightAnchor,
                                                            constant: TabTraySelectorUX.verticalInsets * 2),
            selectionBackgroundView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            selectionBackgroundView.centerXAnchor.constraint(equalTo: buttons[selectedIndex].centerXAnchor)
        ])

        applyTheme(theme: theme)
    }

    private func applyInitalSelectionBackgroundFrame() {
        guard buttons.indices.contains(selectedIndex) else { return }
        layoutIfNeeded()
        let selectedButton = buttons[selectedIndex]
        let width = selectedButton.frame.width + (TabTraySelectorUX.horizontalInsets * 2)

        selectionBackgroundWidthConstraint = selectionBackgroundView.widthAnchor.constraint(equalToConstant: width)
        selectionBackgroundWidthConstraint?.isActive = true
    }

    private func updateLabels() {
        for (index, title) in items.enumerated() {
            guard let button = buttons[safe: index] else { continue }
            button.setTitle(title, for: .normal)
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }
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

        let boldFont = FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
        let boldWidth = ceil(title.size(withAttributes: [.font: boldFont]).width)
        button.widthAnchor.constraint(equalToConstant: boldWidth).isActive = true
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
            button.titleLabel?.font = index == toIndex ?
            FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize) :
            FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
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

        let fromWidth = fromButton.frame.width + (TabTraySelectorUX.horizontalInsets * 2)
        let toWidth = toButton.frame.width + (TabTraySelectorUX.horizontalInsets * 2)
        let selectionIndicatorWidthDuringTransition = fromWidth + (toWidth - fromWidth) * progress

        return SelectionIndicatorTransition(selectionIndicatorWidthDuringTransition: selectionIndicatorWidthDuringTransition,
                                            targetOffset: targetOffset)
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

        for (index, title) in items.enumerated() {
            guard let button = buttons[safe: index] else { continue }
            applyButtonWidthAnchor(on: button, with: title as NSString)
        }

        applyInitalSelectionBackgroundFrame()

        setNeedsLayout()
        layoutIfNeeded()
    }
}
