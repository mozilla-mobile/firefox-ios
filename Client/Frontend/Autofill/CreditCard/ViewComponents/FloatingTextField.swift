// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Shared
import Combine

struct FloatingTextField: View {
    var label: String
    @Binding var textVal: String
    var errorString: String = ""
    var showError: Bool = false
    var keyboardType: UIKeyboardType = .default

    // Theming
    @Environment(\.themeType) var themeVal
    @State var errorColor: Color = .clear
    @State var titleColor: Color = .clear
    @State var textFieldColor: Color = .clear
    @State var backgroundColor: Color = .clear

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(titleColor)
                TextField("", text: $textVal)
                    .font(.body)
                    .padding(.top, 7.5)
                    .foregroundColor(textFieldColor)
                    .keyboardType(keyboardType)
                if showError {
                    HStack(spacing: 0) {
                        Image(ImageIdentifiers.errorAutofill)
                            .renderingMode(.template)
                            .foregroundColor(errorColor)
                        Text(errorString)
                            .errorTextStyle(color: errorColor)
                    }
                    .padding(.top, 7.4)
                }
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.bottom))
        }
        .padding(.leading, 20)
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { val in
            applyTheme(theme: val.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        errorColor = Color(color.textWarning)
        titleColor = Color(color.textPrimary)
        textFieldColor = Color(color.textSecondary)
        backgroundColor = Color(color.layer2)
    }
}
