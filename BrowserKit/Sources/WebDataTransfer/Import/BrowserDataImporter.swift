// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BrowserKit
import UIKit

@available(iOS 26.4, *)
@MainActor
public final class BrowserDataImporter {
    let manager: BEBrowserDataImportManager

    public init(scene: UIWindowScene) {
        manager = BEBrowserDataImportManager(scene: scene)
    }

    public func requestImport() async {
        _ = try? await manager.requestImport(for: BEImportMetadata(supportForImportFromFiles: false))
    }

    public static func token(from userInfo: [AnyHashable: Any]?) -> UUID? {
        return userInfo?[BEBrowserDataImportManager.importTokenUserInfoKey] as? UUID
    }

    /// Receives and saves the data for one import activity. Returns `nil` when the import was cancelled.
    /// - Parameter onAPICompletion: Called once the incoming data ends normally, independently of saving.
    public func importData(
        token: UUID,
        onAPICompletion: @escaping @Sendable () -> Void = {}
    ) async -> BrowserTransferResult? {
        let session = BrowserDataImportSession(onAPICompletion: onAPICompletion)
        return await session.run(manager.importBrowserData(token: token).map(Self.item(for:)))
    }

    nonisolated static func item(for record: BEBrowserData) -> BrowserDataImportItem {
        return BrowserDataImportItem(sourceBrowserName: record.sourceApplicationLocalizedName, payload: .unsupported)
    }
}
