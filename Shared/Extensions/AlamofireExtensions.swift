/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation

public extension SessionManager {
    public static func managerWithUserAgent(_ userAgent: String, configuration: URLSessionConfiguration) -> SessionManager {
        var defaultHeaders = SessionManager.default.session.configuration.httpAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = userAgent
        configuration.httpAdditionalHeaders = defaultHeaders

        return SessionManager(configuration: configuration)
    }
}
