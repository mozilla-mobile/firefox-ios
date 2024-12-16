// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public typealias GUID = String

/// Utilities for futzing with bytes and such.
extension Bytes {
    public class func generateGUID() -> GUID {
        // Turns the standard NSData encoding into the URL-safe variant that Sync expects.
        return generateRandomBytes(9)
            .base64EncodedString(options: [])
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }

    public class func decodeBase64(_ b64: String) -> Data? {
        return Data(base64Encoded: b64, options: [])
    }

    public static func base64urlSafeDecodedData(_ b64: String) -> Data? {
        // Replace the URL-safe chars with their URL-unsafe variants
        // https://en.wikipedia.org/wiki/Base64#Variants_summary_table
        var base64 = b64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }

        if let data = Data(base64Encoded: base64) {
            return data
        }
        return nil
    }

    /**
     * Turn a string of base64 characters into an NSData *without decoding*.
     * This is to allow HMAC to be computed of the raw base64 string.
     */
    public class func dataFromBase64(_ b64: String) -> Data? {
        return b64.data(using: .ascii, allowLossyConversion: false)
    }
}
