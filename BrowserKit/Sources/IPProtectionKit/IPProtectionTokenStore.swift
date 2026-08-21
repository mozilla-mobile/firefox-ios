// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Persists the session credential across launches. Losing it forces re-enrollment
public protocol IPProtectionTokenStore: Sendable {
    func load() -> IPProtectionDeviceSession?
    func save(_ session: IPProtectionDeviceSession) throws
    func clear() throws
}
