/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension NSCharacterSet {
    public static func URLAllowedCharacterSet() -> NSCharacterSet {
        let characterSet = NSMutableCharacterSet()
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLQueryAllowedCharacterSet())
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLUserAllowedCharacterSet())
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLPathAllowedCharacterSet())
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLPasswordAllowedCharacterSet())
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLHostAllowedCharacterSet())
        characterSet.formUnionWithCharacterSet(NSCharacterSet.URLFragmentAllowedCharacterSet())
        return characterSet
    }
}