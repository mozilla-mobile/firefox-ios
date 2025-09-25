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
        // Move animation from viewDidAppear to viewWillAppear for onboarding
        contentViewBottomConstraint?.constant = 0
        UIView.animate(withDuration: viewModel.animationTransitionDuration) {
            self.view.backgroundColor = self.viewModel.backgroundColor
            self.view.layoutIfNeeded()
        }
    }

    // swiftlint:disable:next unneeded_override
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // No animation here - it's handled in viewWillAppear to prevent double animation
    }
}
