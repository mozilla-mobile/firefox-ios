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
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.logins, id: \.self) { login in
                    LoginCellView(
                        login: login,
                        onTap: { viewModel.onLoginCellTap(login) }
                    )
                }
                .font(.caption)
                .foregroundColor(customLightGray)
            }
        }
        .task {
            await viewModel.fetchLogins()
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) {
            applyTheme(theme: $0.theme)
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
        LoginListView(
            viewModel: LoginListViewModel(
                loginStorage: MockLoginStorage(),
                logger: MockLogger(),
                onLoginCellTap: { _ in },
                manageLoginInfoAction: { }
            )
        )
    }
}

import Storage

extension RustLogins: LoginStorage {
    func listLogins() async throws -> [EncryptedLogin] {
        return try await withCheckedThrowingContinuation { continuation in
            self.listLogins().upon { result in
                switch result {
                case .success(let logins):
                    continuation.resume(returning: logins)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

protocol LoginStorage {
    func listLogins() async throws -> [EncryptedLogin]
}

class MockLoginStorage: LoginStorage {
    func listLogins() async throws -> [EncryptedLogin] {
        // Simulate a delay to fetch logins
        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC) // 0.5 seconds

        // Return mock login data
        let mockLogins: [EncryptedLogin] = [
            EncryptedLogin(
                credentials: URLCredential(
                    user: "test",
                    password: "doubletest",
                    persistence: .permanent
                ),
                protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
            ),
            EncryptedLogin(
                credentials: URLCredential(
                    user: "test",
                    password: "doubletest",
                    persistence: .permanent
                ),
                protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
            )
        ]

        return mockLogins
    }
}

class MockLogger: LoggerProtocol {
    func log(_ message: String, level: LogLevel, category: LogCategory, description: String) {
        // Print log messages to the console for simplicity
        print("[\(level)] [\(category)] \(message): \(description)")
    }
}
