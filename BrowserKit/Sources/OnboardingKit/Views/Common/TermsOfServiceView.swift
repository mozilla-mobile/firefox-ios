// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfServiceView<ViewModel: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear

    @StateObject private var viewModel: TosFlowViewModel<ViewModel>
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let onEmbededLinkAction: (TosAction) -> Void

    public init(
        viewModel: TosFlowViewModel<ViewModel>,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onEmbededLinkAction: @escaping (TosAction) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.onEmbededLinkAction = onEmbededLinkAction
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                termsOfServiceViewRegular
            } else {
                termsOfServiceViewCompact
            }
        }
    }

    // MARK: - Regular Layout
    private var termsOfServiceViewRegular: some View {
        TermsOfServiceRegularView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onEmbededLinkAction: onEmbededLinkAction
        )
    }

    // MARK: - Compact Layout
    private var termsOfServiceViewCompact: some View {
        TermsOfServiceCompactView(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onEmbededLinkAction: onEmbededLinkAction
        )
    }
}
