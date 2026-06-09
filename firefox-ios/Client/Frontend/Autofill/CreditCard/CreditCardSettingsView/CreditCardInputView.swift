// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI

import struct MozillaAppServices.CreditCard

struct CreditCardInputView: ThemeableView {
    private struct UX {
        static let cornerRadius: CGFloat = 24
        static let blurRadius: CGFloat = 10
        static let dividerHeight: CGFloat = 0.7
        static let spacerHeight: CGFloat = 4
        static let dividerPaddingTop: CGFloat = 1
        static let inputFieldPaddingTop: CGFloat = 11
        static let removeCardButtonPaddingTop: CGFloat = 28
    }

    @ObservedObject var viewModel: CreditCardInputViewModel
    @State private var isBlurred = false

    // Theming
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State var theme: Theme

    init(
        viewModel: CreditCardInputViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                bodyContent
            }
            .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
        } else {
            NavigationView {
                bodyContent
            }
            .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
        }
    }

    private var bodyContent: some View {
        main
            .blur(radius: isBlurred ? UX.blurRadius : 0)
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.willResignActiveNotification)
            ) { _ in
                isBlurred = true
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification)
            ) { _ in
                isBlurred = false
            }
    }

    private var main: some View {
        return ZStack {
            Color(theme.colors.layer1).ignoresSafeArea()
            form
                .navigationBarTitle(viewModel.state.title,
                                    displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        rightBarButton()
                            .disabled(!viewModel.isRightBarButtonEnabled)
                            .foregroundColor(Color(theme.colors.actionPrimary))
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        leftBarButton()
                            .foregroundColor(Color(theme.colors.actionPrimary))
                    }
                }
                .padding(.top, 0)
                .background(Color(theme.colors.layer1).edgesIgnoringSafeArea(.bottom))
        }
    }

    private var form: some View {
        return VStack(spacing: 0) {
            if #unavailable(iOS 26.0) {
                Divider()
                    .frame(height: UX.dividerHeight)
                    .foregroundColor(.clear)
            }

            name
                .background(Color(theme.colors.layer2))
                .modifier(NewStyleRoundedCorners(topLeadingCorner: UX.cornerRadius,
                                                 topTrailingCorner: UX.cornerRadius,
                                                 bottomLeadingCorner: nil,
                                                 bottomTrailingCorner: nil))

            number
                .background(Color(theme.colors.layer2))

            expiration
                .background(Color(theme.colors.layer2))
                .modifier(NewStyleRoundedCorners(topLeadingCorner: nil,
                                                 topTrailingCorner: nil,
                                                 bottomLeadingCorner: UX.cornerRadius,
                                                 bottomTrailingCorner: UX.cornerRadius))

            Spacer()
                .frame(height: UX.spacerHeight)

            if viewModel.state == .edit {
                RemoveCardButton(windowUUID: windowUUID,
                                 alertDetails: viewModel.removeButtonDetails)
                .padding(.top, UX.removeCardButtonPaddingTop)
            }

            Spacer()
        }
        .modifier(NewStyleExtraPadding())
    }

    private var name: some View {
        return Group {
            CreditCardInputField(windowUUID: windowUUID,
                                 inputType: .name,
                                 showError: !viewModel.nameIsValid,
                                 inputViewModel: viewModel)
            .padding(.top, UX.inputFieldPaddingTop)

            Divider()
                .frame(height: UX.dividerHeight)
                .foregroundColor(.clear)
                .padding(.top, UX.dividerPaddingTop)
        }
    }

    private var number: some View {
        return Group {
            CreditCardInputField(windowUUID: windowUUID,
                                 inputType: .number,
                                 showError: !viewModel.numberIsValid,
                                 inputViewModel: viewModel)
            .padding(.top, UX.inputFieldPaddingTop)

            Divider()
                .frame(height: UX.dividerHeight)
                .foregroundColor(.clear)
                .padding(.top, UX.dividerPaddingTop)
        }
    }

    private var expiration: some View {
        return Group {
            CreditCardInputField(windowUUID: windowUUID,
                                 inputType: .expiration,
                                 showError: viewModel.showExpirationError,
                                 inputViewModel: viewModel)
            .padding(.top, UX.inputFieldPaddingTop)

            if #unavailable(iOS 26.0) {
                Divider()
                    .frame(height: UX.dividerHeight)
                    .foregroundColor(.clear)
                    .padding(.top, UX.dividerPaddingTop)
            }
        }
    }

    func rightBarButton() -> some View {
        let btnState = viewModel.state.rightBarBtn
        return Button(btnState.title) {
            switch btnState {
            case .edit:
                viewModel.updateState(state: .edit)
            case.save:
                // Update existing card
                if viewModel.state == .edit {
                    viewModel.updateCreditCard { _, error in
                        ensureMainThread {
                            guard let error = error else {
                                viewModel.dismiss?(.updatedCard, true)
                                return
                            }
                            viewModel.logger.log("Unable to update card with error: \(error)",
                                                 level: .fatal,
                                                 category: .autofill)
                            viewModel.dismiss?(.none, false)
                        }
                    }
                } else {
                    // Save new card
                    viewModel.saveCreditCard { _, error in
                        ensureMainThread {
                            guard let error = error else {
                                viewModel.dismiss?(.savedCard, true)
                                return
                            }
                            viewModel.logger.log("Unable to save credit card with error: \(error)",
                                                 level: .fatal,
                                                 category: .autofill)
                            viewModel.dismiss?(.savedCard, false)
                        }
                    }
                }
            }
        }
        .modifier(
            CreditCardViewButtonStyle(
                isEnabled: viewModel.isRightBarButtonEnabled,
                theme: theme,
                buttonState: btnState
            )
        )
        .onDisappear {
            viewModel.isRightBarButtonEnabled = false
        }
    }

    func leftBarButton() -> some View {
        let btnState = viewModel.state.leftBarBtn
        return Button(btnState.title) {
            switch btnState {
            case .cancel:
                viewModel.updateState(state: .view)
            case.close:
                viewModel.dismiss?(.none, false)
            }
        }
    }
}

struct CreditCardEditView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCreditCard = CreditCard(guid: "12345678",
                                          ccName: "Tim Apple",
                                          ccNumberEnc: "12345678",
                                          ccNumberLast4: "4321",
                                          ccExpMonth: 1234,
                                          ccExpYear: 2026,
                                          ccType: "Discover",
                                          timeCreated: 1234,
                                          timeLastUsed: nil,
                                          timeLastModified: 1234,
                                          timesUsed: 1234)

        let viewModel = CreditCardInputViewModel(firstName: "Mike",
                                                 lastName: "Simmons",
                                                 errorState: "Temp",
                                                 enteredValue: "",
                                                 creditCard: sampleCreditCard,
                                                 state: .view)

        return CreditCardInputView(
            viewModel: viewModel,
            windowUUID: .XCTestDefaultUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
        )
    }
}
