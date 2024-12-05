// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import Foundation

import struct MozillaAppServices.Login

@MainActor
class LoginListViewModel: ObservableObject {
    @Published var logins: [Login] = []

    private let tabURL: URL
    private let field: FocusFieldType
    private let loginStorage: LoginStorage
    private let logger: Logger
    let onLoginCellTap: (Login) -> Void
    let manageLoginInfoAction: () -> Void

    var shortDisplayString: String {
        tabURL.baseDomain ?? ""
    }

    init(
        tabURL: URL,
        field: FocusFieldType,
        loginStorage: LoginStorage,
        logger: Logger,
        onLoginCellTap: @escaping (Login) -> Void,
        manageLoginInfoAction: @escaping () -> Void
    ) {
        self.tabURL = tabURL
        self.field = field
        self.loginStorage = loginStorage
        self.logger = logger
        self.onLoginCellTap = onLoginCellTap
        self.manageLoginInfoAction = manageLoginInfoAction
    }

    func fetchLogins() async {
        do {
            let logins = try await loginStorage.listLogins()
            self.logins = logins.filter { login in
                if field == FocusFieldType.username && login.decryptedUsername.isEmpty { return false }
                guard let recordHostnameURL = URL(string: login.hostname) else { return false }
                return recordHostnameURL.baseDomain == tabURL.baseDomain
            }
        } catch {
            self.logger.log("Error fetching logins",
                            level: .warning,
                            category: .autofill,
                            description: "Error fetching addresses: \(error.localizedDescription)")
        }
    }
}

class MockLogger: Logger {
    var crashedLastLaunch = false
    var savedMessage: String?
    var savedLevel: LoggerLevel?
    var savedCategory: LoggerCategory?

    func setup(sendUsageData: Bool) {}
    func configure(crashManager: Common.CrashManager) {}
    func copyLogsToDocuments() {}
    func logCustomError(error: Error) {}
    func deleteCachedLogFiles() {}

    func log(_ message: String,
             level: LoggerLevel,
             category: LoggerCategory,
             extra: [String: String]? = nil,
             description: String? = nil,
             file: String = #file,
             function: String = #function,
             line: Int = #line) {
        savedMessage = message
        savedLevel = level
        savedCategory = category
    }
}
