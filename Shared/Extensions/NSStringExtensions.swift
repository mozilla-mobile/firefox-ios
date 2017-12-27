/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    public static func contentsOfFileWithResourceName(_ name: String, ofType type: String, fromBundle bundle: Bundle, encoding: String.Encoding, error: NSErrorPointer) -> String? {
        return bundle.path(forResource: name, ofType: type).flatMap {
            try? String(contentsOfFile: $0, encoding: encoding)
        }
    }
}

