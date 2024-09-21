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

    func fetchLocalRecord<T: RemoteDataTypeRecord>(for type: RemoteDataType) async -> [T]? {
        do {
            let records: [T] = try await type.loadLocalSettingsFromJSON()
            return records
        } catch let error as RemoteDataTypeError {
            logger.log("Failed to fetch local record(s) for \(type.name)",
                       level: .warning,
                       category: .remoteSettings,
                       description: error.localizedDescription)
        } catch {
            logger.log("Error occurred while fetching local record(s) for \(type.name)",
                       level: .warning,
                       category: .remoteSettings,
                       description: error.localizedDescription)
        }
        return nil
    }
}
