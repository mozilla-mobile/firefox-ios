// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// A specialized bottom sheet controller for onboarding flows that uses viewWillAppear for animations
@MainActor
public class OnboardingBottomSheetViewController: BottomSheetViewController {
    private struct UX {
        static let multiplieriPadWidth: CGFloat = 0.75
    }
    private var iPadWidthConstraints: [NSLayoutConstraint] = []
    private var iPadContentConstraints: [NSLayoutConstraint] = []
    private var originalScrollContentWidthConstraint: NSLayoutConstraint?

    // MARK: - View lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupIPadConstraints()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // For onboarding flows, we animate the bottom sheet presentation earlier in the lifecycle
        // This ensures the animation starts before the view becomes visible, creating a smoother
        // user experience during onboarding transitions
        contentViewBottomConstraint?.constant = 0
        UIView.animate(withDuration: viewModel.animationTransitionDuration) {
            self.view.backgroundColor = self.viewModel.backgroundColor
            self.view.layoutIfNeeded()
        }
    }

    // swiftlint:disable:next unneeded_override
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Override viewDidAppear without additional animation logic since we handle
        // all presentation animations in viewWillAppear. This prevents duplicate
        // animations that could cause visual glitches in onboarding flows.
    }

    // MARK: - Private Methods

    private func setupIPadConstraints() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        // Wait for the view hierarchy to be set up, then modify constraints
        DispatchQueue.main.async { [weak self] in
            self?.configureIPadLayout()
        }
    }

    private func configureIPadLayout() {
        // Find and deactivate the existing leading and trailing constraints for sheetView
        let constraintsToRemove = view.constraints.filter { constraint in
            let isLeadingConstraint = (constraint.firstItem === sheetView && constraint.firstAttribute == .leading) ||
                                    (constraint.secondItem === sheetView && constraint.secondAttribute == .leading)
            let isTrailingConstraint = (constraint.firstItem === sheetView && constraint.firstAttribute == .trailing) ||
                                     (constraint.secondItem === sheetView && constraint.secondAttribute == .trailing)
            return isLeadingConstraint || isTrailingConstraint
        }

        NSLayoutConstraint.deactivate(constraintsToRemove)

        // Add new constraints for 75% width and center positioning
        iPadWidthConstraints = [
            sheetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sheetView.widthAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.widthAnchor,
                multiplier: UX.multiplieriPadWidth
            )
        ]

        NSLayoutConstraint.activate(iPadWidthConstraints)
    }
}
