// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Common
import Shared

class RemoteSettingsUtilities {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func fetchLocalRecord<T: RemoteDataTypeRecord>(for type: RemoteDataType) async -> T? {
        do {
            let record: T = try await type.loadLocalSettingsFromJSON()
            logger.log("Successfully fetched record for \(type.name)",
                       level: .info,
                       category: .remoteSettings,
                       description: "Successfully fetched record for \(type.name).")
            return record
        } catch let error as RemoteDataTypeError {
            logger.log("Failed to fetch local record for \(type.name)",
                       level: .warning,
                       category: .remoteSettings,
                       description: error.localizedDescription)
        } catch {
            logger.log("Unexpected error occurred while fetching local record for \(type.name)",
                       level: .warning,
                       category: .remoteSettings,
                       description: error.localizedDescription)
        }
        return nil
    }
}
