// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// A specialized bottom sheet controller for onboarding flows that uses viewWillAppear for animations
@MainActor
public class OnboardingBottomSheetViewController: BottomSheetViewController {
    // MARK: - View lifecycle

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
}
