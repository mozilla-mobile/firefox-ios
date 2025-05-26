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

class TabTraySelectorView: UIView,
                           ThemeApplicable {
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int {
        didSet {
            if oldValue != selectedIndex {
                selectNewSection(from: oldValue, to: selectedIndex)
            }
        }
    }
    private var buttons: [UIButton] = []
    private lazy var selectionBackgroundView: UIView = .build { _ in }
    private var selectionBackgroundWidthConstraint: NSLayoutConstraint?

    var items: [String] = ["", "", ""] {
        didSet {
            updateLabels()
            // We need the labels on the buttons to adjust proper frame size
            applyInitalSelectionBackgroundFrame()
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

<<<<<<< HEAD
=======
    func updateSelectionProgress(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        updateSelectionBackground(from: fromIndex, to: toIndex, progress: abs(progress), animated: false)
        simulateFontWeightTransition(from: fromIndex, to: toIndex, progress: abs(progress))
    }

    func didFinishSelection(to index: Int) {
        selectedIndex = index
        adjustSelectedButtonFont(toIndex: index)
    }

>>>>>>> e640ee78b (Bugfix FXIOS-12327 [Tab tray UI experiment] Fix font jitter when swiping (#26853))
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
        let preferredFont = UIFont.preferredFont(forTextStyle: .body)
        let baseFontSize = preferredFont.pointSize

        let boldFont = UIFont.systemFont(ofSize: baseFontSize, weight: .bold)
        let boldWidth = title.size(withAttributes: [.font: boldFont]).width
        button.widthAnchor.constraint(equalToConstant: boldWidth).isActive = true
    }

    @objc
    private func sectionSelected(_ sender: UIButton) {
        selectedIndex = sender.tag
    }

    private func selectNewSection(from fromIndex: Int, to toIndex: Int) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        let toButton = buttons[toIndex]
        for (index, button) in buttons.enumerated() {
            button.transform = .identity
            button.titleLabel?.font = index == toIndex ?
            FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize) :
            FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
        }

<<<<<<< HEAD
        let newWidth = toButton.frame.width + (TabTraySelectorUX.horizontalInsets * 2)
        let toCenterX = toButton.superview!.convert(toButton.center, to: self).x
        let offsetX = toCenterX - selectionBackgroundView.center.x
=======
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
>>>>>>> e640ee78b (Bugfix FXIOS-12327 [Tab tray UI experiment] Fix font jitter when swiping (#26853))

        selectionBackgroundWidthConstraint?.constant = newWidth

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.selectionBackgroundView.transform = CGAffineTransform(translationX: offsetX, y: 0)
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
