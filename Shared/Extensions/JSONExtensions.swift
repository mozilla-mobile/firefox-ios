/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftyJSON

public extension JSON {
    func isStringOrNull() -> Bool {
        return isNull() || isString()
    }

    func isError() -> Bool {
        return self.error != nil
    }

    func isString() -> Bool {
        return self.type == .string
    }

    func isBool() -> Bool {
        return self.type == .bool
    }

    func isArray() -> Bool {
        return self.type == .array
    }

    func isDictionary() -> Bool {
        return self.type == .dictionary
    }

    func isNull() -> Bool {
        return self.type == .null
    }

    func isInt() -> Bool {
        return self.type == .number && self.int != nil
    }

    func isNumber() -> Bool {
        return self.type == .number && self.number != nil
    }

    func isDouble() -> Bool {
        return self.type == .number && self.double != nil
    }
}
