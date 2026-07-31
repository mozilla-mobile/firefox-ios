// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

final class MockRemoteSettingsService: RemoteSettingsService, @unchecked Sendable {
    private let syncResult: [String]

    init(syncResult: [String]) {
        self.syncResult = syncResult
        super.init(noHandle: NoHandle())
    }

    required init(unsafeFromHandle handle: UInt64) {
        self.syncResult = []
        super.init(unsafeFromHandle: handle)
    }

    override func sync() throws -> [String] {
        return syncResult
    }
}
