// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct FloatingTextField: View {
    var label: String
    @Binding var textVal: String
    var placeHolder: String = "Enter something here..."
    var errorString: String = ""
    var showError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.gray)
            TextField(placeHolder, text: $textVal)
                .font(.system(size: 17))
                .padding(.top, 7.5)
            if showError {
                HStack (spacing: 0) {
                    Image("error-autofill")
                    Text(errorString)
                        .errorTextStyle()
                        
                }
                .padding(.top, 7.4)
            }
        }
        .padding(.leading, 16)
    }
}
