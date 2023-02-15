// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct RemoveCardButton: View {
    @State private var showAlert = false

    struct AlertDetails {
        let alertTitle: Text
        let alertBody: Text?
        let primaryButtonStyleAndText: Alert.Button
        let secondaryButtonStyleAndText: Alert.Button

        let primaryButtonAction: () -> Void
        let secondaryButtonAction: (() -> Void)?
    }

    let removeButtonColor: Color
    let borderColor: Color
    let alertDetails: AlertDetails

    var body: some View {
        VStack {
            Rectangle()
                .fill(borderColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
            VStack {
                Button(String.CreditCard.EditCard.RemoveCardButtonTitle) {
                    showAlert.toggle()
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: alertDetails.alertTitle,
                        message: alertDetails.alertBody,
                        primaryButton: alertDetails.primaryButtonStyleAndText,
                        secondaryButton: alertDetails.secondaryButtonStyleAndText
                    )
                }
                .font(.body)
                .foregroundColor(removeButtonColor)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            }
            Rectangle()
                .fill(borderColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
        }
    }
}
