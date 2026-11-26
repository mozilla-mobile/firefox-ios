// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebDataTransfer

/// Receives browser data imports for one window scene.
@available(iOS 26.4, *)
@MainActor
final class BrowserDataImportHandler {
    private let importer: BrowserDataImporter
    private let logger: Logger

    init(windowScene: UIWindowScene, logger: Logger = DefaultLogger.shared) {
        self.importer = BrowserDataImporter(scene: windowScene)
        self.logger = logger
    }

    func receiveImport(from userActivity: NSUserActivity) {
        guard let token = BrowserDataImporter.token(from: userActivity.userInfo) else {
            logger.log("Browser data import activity has no valid token", level: .warning, category: .lifecycle)
            return
        }

        Task {
            guard let result = await importer.importData(token: token) else { return }
            logger.log("Browser data import finished: \(result.outcome)", level: .info, category: .lifecycle)
        }
    }
}
