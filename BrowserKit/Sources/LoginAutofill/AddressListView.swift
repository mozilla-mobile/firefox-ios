// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: - LoginListView

/// A view displaying a list of login information.
struct LoginListView: View {
    // MARK: - Properties

    @Environment(\.themeType)
    var themeVal
    @ObservedObject var viewModel: LoginListViewModel
    @State private var customLightGray: Color = .clear

    // MARK: - Body

    var body: some View {
        List {
            if viewModel.showSection {
                Section(header: Text("Saved Logins")) {
                    ForEach(viewModel.logins, id: \.id) { login in
                        LoginCellView(
                            login: login,
                            onTap: {
                                // Handle action when login cell is tapped.
                            }
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(customLightGray)
            }
        }
        .listStyle(.plain)
        .listRowInsets(EdgeInsets())
        .onAppear {
            viewModel.fetchLogins()
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        customLightGray = Color(color.textSecondary)
    }
}

struct LoginListView_Previews: PreviewProvider {
    static var previews: some View {
        LoginListView(viewModel: LoginListViewModel(loginStorage: MockLoginStorage(), logger: MockLogger()))
    }
}

class MockLoginStorage: LoginStorage {
    func listAllLogins(completion: @escaping ([Login]?, Error?) -> Void) {
        // Simulate a delay to fetch logins
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Return mock login data
            let mockLogins = [
                Login(website: "http://firefox.com", username: "foo@example.com"),
                Login(website: "http://firefox.com", username: "bar@example.com")
            ]
            completion(mockLogins, nil)
        }
    }
}

class MockLogger: LoggerProtocol {
    func log(_ message: String, level: LogLevel, category: LogCategory, description: String) {
        // Print log messages to the console for simplicity
        print("[\(level)] [\(category)] \(message): \(description)")
    }
}
