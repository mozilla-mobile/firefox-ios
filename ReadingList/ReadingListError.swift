/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// TODO This needs to encapsulate an NSError eventually
public class ReadingListError: MaybeErrorType {
    var message: String
    init(_ message: String) {
        self.message = message
    }
    public var description: String {
        return message
    }
}
