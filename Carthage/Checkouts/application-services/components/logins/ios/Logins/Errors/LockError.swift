/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum LockError: Error {
    /// Indicates that lock/unlock pairs were mismatched
    case mismatched
    /// Indicates a use attempt when the database is locked
    case locked
}
