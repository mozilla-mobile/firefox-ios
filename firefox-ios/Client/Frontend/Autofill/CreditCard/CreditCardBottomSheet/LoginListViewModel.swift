// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LoginStorage {
    func listAllLogins(completion: @escaping ([Login]?, Error?) -> Void)
}

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
    var onLoginCellTap: (Login) -> Void

    init(
        loginStorage: LoginStorage,
        logger: LoggerProtocol,
        onLoginCellTap: @escaping (Login) -> Void
    ) {
        self.loginStorage = loginStorage
        self.logger = logger
        self.onLoginCellTap = onLoginCellTap
    }

    func fetchLogins() {
        loginStorage.listAllLogins { [weak self] storedLogins, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let logins = storedLogins {
                    self.logins = logins
                } else if let error = error {
                    self.logger.log("Error fetching logins",
                                    level: .warning,
                                    category: .login,
                                    description: "Error fetching logins: \(error.localizedDescription)")
                }
            }
        }
    }
}
