// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebDataTransfer

@available(iOS 26.4, *)
@MainActor
protocol BrowserDataImporting {
    func importData(token: UUID, onAPICompletion: @escaping @Sendable () -> Void) async -> BrowserTransferResult?
}

@available(iOS 26.4, *)
extension BrowserDataImporter: BrowserDataImporting {}

/// Receives browser data imports for one window scene.
@available(iOS 26.4, *)
@MainActor
final class BrowserDataImportHandler {
    private let importer: BrowserDataImporting
    private let logger: Logger

    convenience init(windowScene: UIWindowScene, logger: Logger = DefaultLogger.shared) {
        self.init(importer: BrowserDataImporter(scene: windowScene), logger: logger)
    }

    init(importer: BrowserDataImporting, logger: Logger = DefaultLogger.shared) {
        self.importer = importer
        self.logger = logger
    }

    /// Returns the task that receives the data, or `nil` when the activity has no import token.
    @discardableResult
    func receiveImport(from userActivity: NSUserActivity) -> Task<Void, Never>? {
        guard let token = BrowserDataImporter.token(from: userActivity.userInfo) else {
            logger.log("Browser data import activity has no valid token", level: .warning, category: .lifecycle)
            return nil
        }

        return Task {
            guard let result = await importer.importData(token: token, onAPICompletion: {}) else { return }
            logger.log("Browser data import finished: \(result.outcome)", level: .info, category: .lifecycle)
        }
    }
}
