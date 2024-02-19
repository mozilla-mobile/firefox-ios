// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Shared

struct LoginAutoFillView: View {
    @Environment(\.themeType)
    var themeVal

    var body: some View {
        VStack {
            LoginAutoFillHeaderView(
                title: String.PasswordAutofill.UseSavedPasswordFromHeader,
                header: String(format: String.PasswordAutofill.SignInWithSavedPassword, "cnn.com")
            )
            LoginListView(
                viewModel: LoginListViewModel(
                    loginStorage: MockLoginStorage(),
                    logger: MockLogger(),
                    onLoginCellTap: { login in
                    }
                )
            )
            LoginAutoFillFooterView(
                title: String.PasswordAutofill.ManagePasswordsButton,
                accessibilityIdentifier: "manageLoginInfoButton"
            )
        }
        .padding()
        .background(Color(themeVal.theme.colors.layer1))
    }
}

#Preview {
    LoginAutoFillView()
}
