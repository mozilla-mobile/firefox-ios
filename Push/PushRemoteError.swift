// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftyJSON

// public struct PushRemoteError {
//    static let MissingNecessaryCryptoKeys: Int32 = 101
//    static let InvalidURLEndpoint: Int32         = 102
//    static let ExpiredURLEndpoint: Int32         = 103
//    static let DataPayloadTooLarge: Int32        = 104
//    static let EndpointBecameUnavailable: Int32  = 105
//    static let InvalidSubscription: Int32        = 106
//    static let RouterTypeIsInvalid: Int32        = 108
//    static let InvalidAuthentication: Int32      = 109
//    static let InvalidCryptoKeysSpecified: Int32 = 110
//    static let MissingRequiredHeader: Int32      = 111
//    static let InvalidTTLHeaderValue: Int32      = 112
//    static let UnknownError: Int32               = 999
// }

public struct PushRemoteError {
    let code: Int
    let errorNumber: Int
    let error: String
    let message: String?

    public static func from(json: JSON) -> PushRemoteError? {
        guard let code = json["code"].int,
              let errorNumber = json["errno"].int,
              let error = json["error"].string
        else { return nil }

        let message = json["message"].string
        return PushRemoteError(code: code, errorNumber: errorNumber, error: error, message: message)
    }
}
