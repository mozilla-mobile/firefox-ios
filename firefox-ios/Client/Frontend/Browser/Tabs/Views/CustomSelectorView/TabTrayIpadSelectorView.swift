// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class TabTrayiPadSelectorView: TabTraySelectorView {
    private struct iPadUX {
        static let stackViewHorizontalSpacing: CGFloat = 80
        static let verticalSpacing: CGFloat = 8
    }

    private var selectionBackgroundConstraints: [NSLayoutConstraint] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBackgroundView.layer.cornerRadius = selectionBackgroundView.frame.height / 2
        if #available(iOS 26, *) {
            visualEffectView.layer.cornerRadius = containerView.bounds.height / 2
        }
    }

    override func setupViewHierarchy() {
        if #available(iOS 26, *) {
            addSubview(visualEffectView)
        }
        addSubview(containerView)
        containerView.addSubview(stackView)
        insertSubview(selectionBackgroundView, belowSubview: containerView)
        selectionBackgroundView.clipsToBounds = true
        selectionBackgroundView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.iPadSelectionBackgroundView
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: iPadUX.verticalSpacing),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -iPadUX.verticalSpacing),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                   constant: UX.containerHorizontalSpacing),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                    constant: -UX.containerHorizontalSpacing),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: iPadUX.verticalSpacing),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                               constant: iPadUX.stackViewHorizontalSpacing),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                              constant: -iPadUX.verticalSpacing),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                constant: -iPadUX.stackViewHorizontalSpacing),
        ])

        if #available(iOS 26, *) {
            NSLayoutConstraint.activate([
                visualEffectView.topAnchor.constraint(equalTo: containerView.topAnchor),
                visualEffectView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                visualEffectView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                visualEffectView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
        }
    }

    override func applyInitialConstraints() {
        updateSelectionBackground()
    }

    override func setupGestures() {
        // No swipe gestures on iPad, the static layout selects via tap only.
    }

    override func updateSelectionProgress(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        updateSelectionBackground()
        simulateFontWeightTransition(from: fromIndex, to: toIndex, progress: abs(progress))
    }

    override func selectNewSection(from fromIndex: Int, to toIndex: Int, sender: UIButton) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        updateSelectionBackground()
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }
        adjustSelectedButtonFont(toIndex: toIndex)

        let panelType = TabTrayPanelType.getExperimentConvert(index: toIndex)
        delegate?.didSelectSection(panelType: panelType)
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
}
