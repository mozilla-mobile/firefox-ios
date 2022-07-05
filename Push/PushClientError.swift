// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

public enum PushClientError: MaybeErrorType {
    case Remote(PushRemoteError)
    case Local(Error)

    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error
            let messageString = error.message ?? ""
            return "<FxAClientError.Remote \(error.code)/\(error.errorNumber): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error \"\(error.localizedDescription)\">"
        }
    }
}
