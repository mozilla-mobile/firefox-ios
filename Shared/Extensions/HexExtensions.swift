/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    public var hexDecodedData: Data {
        // Convert to a CString and make sure it has an even number of characters (terminating 0 is included, so we
        // check for uneven!)
        guard let cString = self.cString(using: String.Encoding.ascii), (cString.count % 2) == 1 else {
            return Data()
        }
        guard let result = NSMutableData(capacity: (cString.count - 1) / 2) else {
            return Data()
        }
        for i in stride(from: 0, to: (cString.count - 1), by: 2) {
            guard let l = hexCharToByte(cString[i]), let r = hexCharToByte(cString[i+1]) else {
                return Data()
            }
            var value: UInt8 = (l << 4) | r
            result.append(&value, length: MemoryLayout.size(ofValue: value))
        }
        return result as Data
    }

    fileprivate func hexCharToByte(_ c: CChar) -> UInt8? {
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

extension Data {
    public var hexEncodedString: String {
        let result = NSMutableString(capacity: count * 2)
        withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            for i in 0..<count {
                result.append(HexDigits[Int((p[i] & 0xf0) >> 4)])
                result.append(HexDigits[Int(p[i] & 0x0f)])
            }
        }
        return String(result)
    }

    public static func randomOfLength(_ length: UInt) -> Data? {
        let length = Int(length)
        if let data = NSMutableData(length: length) {
            _ = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes.assumingMemoryBound(to: UInt8.self))
            return (NSData(data: data as Data) as Data)
        } else {
            return nil
        }
    }
}

extension Data {
    public var base64EncodedString: String {
        return self.base64EncodedString(options: NSData.Base64EncodingOptions())
    }
}
