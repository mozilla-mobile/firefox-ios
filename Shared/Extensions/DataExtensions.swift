/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Data {
    public mutating func appendBytes(fromData data: Data) {
        var bytes = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &bytes, count: data.count)
        self.append(bytes, count: bytes.count)
    }

    public func getBytes() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &bytes, count: self.count)
        return bytes
    }
}
