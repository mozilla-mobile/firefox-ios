// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import SwiftUI
import Shared

struct CreditCardInputView: View {
    @ObservedObject var viewModel: CreditCardInputViewModel
    var dismiss: ((_ successVal: Bool) -> Void)

    // Theming
    @Environment(\.themeType) var themeVal
    @State var backgroundColor: Color = .clear
    @State var removeButtonColor: Color = .clear
    @State var borderColor: Color = .clear
    @State var textFieldBackgroundColor: Color = .clear

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    Divider()
                        .frame(height: 0.7)
                        .foregroundColor(borderColor)

                    Group {
                        CreditCardInputField(inputType: .name,
                                             showError: !viewModel.nameIsValid,
                                             inputViewModel: viewModel)
                        .padding(.top, 11)

                        Divider()
                            .frame(height: 0.7)
                            .foregroundColor(borderColor)
                            .padding(.top, 1)
                    }
                    .background(textFieldBackgroundColor)

                    Group {
                        CreditCardInputField(inputType: .number,
                                             showError: !viewModel.numberIsValid,
                                             inputViewModel: viewModel)
                        .padding(.top, 11)

                        Divider()
                            .frame(height: 0.7)
                            .foregroundColor(borderColor)
                            .padding(.top, 1)
                    }
                    .background(textFieldBackgroundColor)

                    Group {
                        CreditCardInputField(inputType: .expiration,
                                             showError: !viewModel.expirationIsValid,
                                             inputViewModel: viewModel)
                        .padding(.top, 11)

                        Divider()
                            .frame(height: 0.7)
                            .foregroundColor(borderColor)
                            .padding(.top, 1)
                    }
                    .background(textFieldBackgroundColor)

                    Spacer()
                        .frame(height: 4)

                    if viewModel.state == .edit {
                        RemoveCardButton(
                            removeButtonColor: removeButtonColor,
                            borderColor: borderColor,
                            alertDetails: viewModel.removeButtonDetails
                        )
                        .padding(.top, 28)
                    }

                    Spacer()
                }
                .navigationBarTitle(viewModel.state.title,
                                    displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        rightBarButton()
                            .disabled(!viewModel.isRightBarButtonEnabled)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        leftBarButton()
                    }
                }
                .padding(.top, 0)
                .background(backgroundColor.edgesIgnoringSafeArea(.bottom))
            }
            .onAppear {
                applyTheme(theme: themeVal.theme)
            }
            .onChange(of: themeVal) { val in
                applyTheme(theme: val.theme)
            }
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        backgroundColor = Color(color.layer1)
        removeButtonColor = Color(color.textWarning)
        borderColor = Color(color.borderPrimary)
        textFieldBackgroundColor = Color(color.layer2)
    }

    func rightBarButton() -> some View {
        let btnState = viewModel.state.rightBarBtn
        return Button(btnState.title) {
            switch btnState {
            case .edit:
                viewModel.updateState(state: .edit)
            case.save:
                viewModel.saveCreditCard { _, error in
                    guard error != nil else {
                        dismiss(true)
                        return
                    }
                    dismiss(false)
                }
            }
        }
    }

    func leftBarButton() -> some View {
        let btnState = viewModel.state.leftBarBtn
        return Button(btnState.title) {
            switch btnState {
            case .cancel:
                viewModel.updateState(state: .view)
            case.close:
                dismiss(false)
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
            dismiss: { successVal in
            // dismiss view
        })
    }
}
