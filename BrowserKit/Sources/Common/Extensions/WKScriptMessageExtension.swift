// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

public extension WKScriptMessage {
    func decodeBody<T: Decodable>(as type: T.Type) -> T? {
        if let dict = (body as? [String: Any]), let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            return try? JSONDecoder().decode(type, from: data)
        } else if let bodyString = body as? String, let data = bodyString.data(using: .utf8) {
            return try? JSONDecoder().decode(type, from: data)
        } else {
            return nil
        }
    }
}
