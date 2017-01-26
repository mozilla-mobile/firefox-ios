/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

/**
 * Used to bridge the NSErrors we get here into something that Result is happy with.
 */
open class DatabaseError: MaybeErrorType {
    let err: NSError?

    open var description: String {
        return err?.localizedDescription ?? "Unknown database error."
    }

    public init(description: String) {
        self.err = NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: description])
    }

    public init(err: NSError?) {
        self.err = err
    }
}
