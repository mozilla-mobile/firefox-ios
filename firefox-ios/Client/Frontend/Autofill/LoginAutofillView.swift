// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Shared
import Common

struct LoginAutofillView: View {
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager

    @ObservedObject var viewModel: LoginListViewModel
    @State private var backgroundColor: Color = .clear

    var body: some View {
        VStack {
            AutofillHeaderView(
                windowUUID: windowUUID,
                title: String.PasswordAutofill.UseSavedPasswordFromHeader,
                subtitle: String(format: String.PasswordAutofill.SignInWithSavedPassword, viewModel.shortDisplayString)
            )
            LoginListView(windowUUID: windowUUID,
                          viewModel: viewModel)
            AutofillFooterView(
                windowUUID: windowUUID,
                title: String.PasswordAutofill.ManagePasswordsButton,
                primaryAction: viewModel.manageLoginInfoAction
            )
        }
        .padding()
        .background(backgroundColor)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        backgroundColor = Color(color.layer1)
    }
}

#Preview {
    LoginAutofillView(
        windowUUID: .XCTestDefaultUUID,
        viewModel: LoginListViewModel(
            tabURL: URL(string: "http://www.example.com", invalidCharacters: false)!,
            field: FocusFieldType.username,
            loginStorage: MockLoginStorage(),
            logger: MockLogger(),
            onLoginCellTap: { _ in },
            manageLoginInfoAction: { }
        )
    )
}
