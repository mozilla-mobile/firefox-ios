// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct FloatingTextField: View {
    struct Colors {
        let errorColor: Color
        let titleColor: Color
        let textFieldColor: Color
    }

    var label: String
    @Binding var textVal: String
    var errorString: String = ""
    var showError: Bool = false
    var colors: Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(colors.titleColor)
            TextField("", text: $textVal)
                .font(.system(size: 17))
                .padding(.top, 7.5)
                .foregroundColor(colors.textFieldColor)
            if showError {
                HStack(spacing: 0) {
                    Image("error-autofill")
                    Text(errorString)
                        .errorTextStyle(color: colors.errorColor)
                }
                .padding(.top, 7.4)
            }
        }
        .padding(.leading, 16)
    }
}
