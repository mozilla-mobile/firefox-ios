/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

/// Interface for saving and retrieving metadata web content
public protocol Metadata {
    @discardableResult func storeMetadata(_ metadata: PageMetadata, forPageURL: URL, expireAt: UInt64) -> Success
    func deleteExpiredMetadata() -> Success
}
