/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation

public extension Alamofire.Manager {
    public static func managerWithUserAgent(userAgent: String, configuration: NSURLSessionConfiguration) -> Alamofire.Manager {
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = userAgent
        configuration.HTTPAdditionalHeaders = defaultHeaders

        return Alamofire.Manager(configuration: configuration)
    }
}