// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfUseView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @StateObject private var viewModel: TermsOfUseFlowViewModel<ViewModel>
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    public init(
        viewModel: TermsOfUseFlowViewModel<ViewModel>,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                termsOfUseViewRegular
            } else {
                termsOfUseViewCompact
            }
        }
    }

    // MARK: - Regular Layout
    private var termsOfUseViewRegular: some View {
        TermsOfUseRegularView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
    }

    // MARK: - Compact Layout
    private var termsOfUseViewCompact: some View {
        TermsOfUseCompactView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
    }
}
