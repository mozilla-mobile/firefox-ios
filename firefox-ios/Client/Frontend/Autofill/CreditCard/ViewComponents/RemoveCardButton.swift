// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI
import Shared

struct RemoveCardButton: View {
    // Theming
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State private var showAlert = false

    struct AlertDetails {
        let alertTitle: Text
        let alertBody: Text?
        let primaryButtonStyleAndText: Alert.Button
        let secondaryButtonStyleAndText: Alert.Button

        let primaryButtonAction: () -> Void
        let secondaryButtonAction: (() -> Void)?
    }

    @State var removeButtonColor: Color = .clear
    @State var borderColor: Color = .clear
    @State var backgroundColor: Color = .clear
    let alertDetails: AlertDetails

    var body: some View {
        ZStack {
            VStack {
                Rectangle()
                    .fill(borderColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 0.7)
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
            }.background(backgroundColor.edgesIgnoringSafeArea(.bottom))
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // part of FXIOS-6797, if the app goes to the background and
            // then the user fails the biometric authentication this alert
            // prevents the screen dismissal, hiding it is the simplest way to solve the issue.
            showAlert = false
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        backgroundColor = Color(color.layer2)
        removeButtonColor = Color(color.textCritical)
        borderColor = Color(color.borderPrimary)
    }
}
