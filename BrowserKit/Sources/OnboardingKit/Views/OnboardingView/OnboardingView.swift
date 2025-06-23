// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

// MARK: - Main Onboarding View
public struct OnboardingView<VM: OnboardingCardInfoModelProtocol>: View {
    @Environment(\.deviceType)
    var deviceType
    @StateObject private var viewModel: OnboardingFlowViewModel<VM>
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    public init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingFlowViewModel<VM>
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }

    public var body: some View {
        Group {
            switch deviceType {
            case .pad:
                iPadOnboardingView
            default:
                iPhoneOnboardingView
            }
        }
    }

    // MARK: - iPad Layout
    private var iPadOnboardingView: some View {
        OnboardingViewiPad(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel
        )
    }

    // MARK: - iPhone Layout
    private var iPhoneOnboardingView: some View {
        OnboardingViewiPhone(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel
        )
    }
}
