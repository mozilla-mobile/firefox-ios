/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    public var hexDecodedData: NSData {
        // Convert to a CString and make sure it has an even number of characters (terminating 0 is included, so we
        // check for uneven!)
        guard let cString = self.cStringUsingEncoding(NSASCIIStringEncoding) where (cString.count % 2) == 1 else {
            return NSData()
        }
        guard let result = NSMutableData(capacity: (cString.count - 1) / 2) else {
            return NSData()
        }
        for i in 0.stride(to: (cString.count - 1), by: 2) {
            guard let l = hexCharToByte(cString[i]), r = hexCharToByte(cString[i+1]) else {
                return NSData()
            }
            var value: UInt8 = (l << 4) | r
            result.appendBytes(&value, length: sizeofValue(value))
        }
        return result
    }

    private func hexCharToByte(c: CChar) -> UInt8? {
        if c >= 48 && c <= 57 { // 0 - 9
            return UInt8(c - 48)
        }
        if c >= 97 && c <= 102 { // a - f
            return 10 + UInt8(c - 97)
        }
        if c >= 65 && c <= 70 { // A - F
            return 10 + UInt8(c - 65)
        }
        return nil
    }
}

private let HexDigits: [String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

extension NSData {
    public var hexEncodedString: String {
        let result = NSMutableString(capacity: length * 2)
        let p = UnsafePointer<UInt8>(bytes)
        for i in 0..<length {
            result.appendString(HexDigits[Int((p[i] & 0xf0) >> 4)])
            result.appendString(HexDigits[Int(p[i] & 0x0f)])
        }
        return String(result)
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
