// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct SwiftUIView: View {
    @Environment(\.themeType)
    var themeVal

    var body: some View {
        VStack {
            LoginAutoFillHeaderView(
                title: "Use this login?",
                header: "You’ll sign into cnn.com"
            )
            LoginListView(
                viewModel: LoginListViewModel(
                    loginStorage: MockLoginStorage(),
                    logger: MockLogger()
                )
            )
            LoginAutoFillFooterView(
                title: "Manage passwords",
                accessibilityIdentifier: "manageLoginInfoButton"
            )
        }
        .padding()
        .background(Color(themeVal.theme.colors.layer1))
    }
}

#Preview {
    SwiftUIView()
}
