// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

// MARK: - Main Onboarding View
public struct OnboardingView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @StateObject private var viewModel: OnboardingFlowViewModel<ViewModel>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    public init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingFlowViewModel<ViewModel>
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                onboardingViewRegular
            } else {
                onboardingViewCompact
            }
        }
    }

    // MARK: - Regular Layout
    private var onboardingViewRegular: some View {
        OnboardingViewRegular(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel
        )
    }

    // MARK: - Compact Layout
    private var onboardingViewCompact: some View {
        OnboardingViewCompact(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel
        )
    }
}
