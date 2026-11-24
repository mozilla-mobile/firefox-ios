// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

/// Gradient applied to the onboarding sheet hero image, resolved against the current theme.
public enum OnboardingSheetHeroGradient: Equatable {
    case aiStrong
    case accent

    func linearGradient(for theme: Theme) -> LinearGradient {
        switch self {
        case .aiStrong:
            return LinearGradient(
                colors: [
                    theme.colors.gradientAIStrongStop1.color,
                    theme.colors.gradientAIStrongStop2.color,
                    theme.colors.gradientAIStrongStop3.color
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .accent:
            return LinearGradient(
                gradient: theme.colors.gradientAccent.swiftUI,
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
