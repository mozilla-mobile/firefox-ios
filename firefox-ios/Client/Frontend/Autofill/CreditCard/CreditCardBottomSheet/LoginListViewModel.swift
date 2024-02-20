// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LoggerProtocol {
    func log(_ message: String, level: LogLevel, category: LogCategory, description: String)
}

enum LogLevel {
    case info, warning, error
}

enum LogCategory {
    case login
}

class LoginListViewModel: ObservableObject {
    @Published var logins: [Login] = []

    private let loginStorage: LoginStorage
    private let logger: LoggerProtocol
    let onLoginCellTap: (Login) -> Void
    let manageLoginInfoAction: () -> Void

    init(
        loginStorage: LoginStorage,
        logger: LoggerProtocol,
        onLoginCellTap: @escaping (Login) -> Void,
        manageLoginInfoAction: @escaping () -> Void
    ) {
        self.loginStorage = loginStorage
        self.logger = logger
        self.onLoginCellTap = onLoginCellTap
        self.manageLoginInfoAction = manageLoginInfoAction
    }

    func fetchLogins() async {
        do {
            self.logins = try await loginStorage.listLogins()
        } catch {
            self.logger.log("Error fetching logins",
                            level: .warning,
                            category: .login,
                            description: "Error fetching logins: \(error.localizedDescription)")
        }
    }
}
