/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Base32
import Foundation

extension String {
    public var hexDecodedData: NSData {
        return base16DecodeToData(self)!
    }
}

extension NSData {
    public var hexEncodedString: String {
        return base16Encode(self, uppercase: false)
    }

    public class func randomOfLength(length: UInt) -> NSData? {
        let length = Int(length)
        if let data = NSMutableData(length: length) {
            _ = SecRandomCopyBytes(kSecRandomDefault, length, UnsafeMutablePointer<UInt8>(data.mutableBytes))
            return NSData(data: data)
        } else {
            return nil
        }
    }
}

extension NSData {
    public var base64EncodedString: String {
        return base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
}
