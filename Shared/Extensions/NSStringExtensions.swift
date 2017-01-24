/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension NSString {
    public class func contentsOfFileWithResourceName(name: String, ofType type: String, fromBundle bundle: NSBundle, encoding: NSStringEncoding, error: NSErrorPointer) -> NSString? {
        if let path = bundle.pathForResource(name, ofType: type) {
            do {
                return try NSString(contentsOfFile: path, encoding: encoding)
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
}


