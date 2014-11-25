// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AlamoFire

private let BASE_URL = "https://moz-syncapi.sateh.com/1.0/"

enum RequestError {
    case BadAuth
    case ConnectionFailed
}

class RestAPI {
    class func sendRequest(credential: NSURLCredential, request: String, success: (data: AnyObject?) -> (), error: (error: RequestError) -> ()) {
        Alamofire.request(.GET, BASE_URL + request)
            .authenticate(usingCredential: credential)
            .responseJSON { (request, response, data, err) in
                switch response?.statusCode {
                case .Some(let status) where status == 200:
                    success(data: data)
                case .Some(let status) where status == 401:
                    error(error: .BadAuth)
                default:
                    error(error: .ConnectionFailed)
                }
        }
    }
}
