// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import ComponentLibrary
import Common

public struct TermsOfServiceView<VM: OnboardingCardInfoModelProtocol>: View {
    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var secondaryActionColor: Color = .clear

    @StateObject private var viewModel: TosFlowViewModel<VM>
    @Environment(\.deviceType)
    var deviceType
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    public let onEmbededLinkAction: (TosAction) -> Void

    public init(
        viewModel: TosFlowViewModel<VM>,
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
            switch deviceType {
            case .pad:
                iPadTermsOfServiceView
            default:
                iPhoneTermsOfServiceView
            }
        }
    }

    // MARK: - iPad Layout
    private var iPadTermsOfServiceView: some View {
        TermsOfServiceViewiPad(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onEmbededLinkAction: onEmbededLinkAction
        )
    }

    // MARK: - iPhone Layout
    private var iPhoneTermsOfServiceView: some View {
        TermsOfServiceViewiPhone(
            viewModel: viewModel,
            windowUUID: windowUUID,
            themeManager: themeManager,
            onEmbededLinkAction: onEmbededLinkAction
        )
    }
}
