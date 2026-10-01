// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

open class Bytes {
    open class func generateRandomBytes(_ len: UInt) -> Data {
        let len = Int(len)
        var data = Data(count: len)
        data.withUnsafeMutableBytes { (p: UnsafeMutableRawBufferPointer) in
            guard let p = p.bindMemory(to: UInt8.self).baseAddress else {
                fatalError("Random byte generation failed.")
            }
            if SecRandomCopyBytes(kSecRandomDefault, len, p) != errSecSuccess {
                fatalError("Random byte generation failed.")
            }
        }
        return data
    }
}
