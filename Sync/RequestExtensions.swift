/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responseParsedJSON(completionHandler: ResponseHandler) -> Self {
        return response(serializer: Request.ParsedJSONResponseSerializer(), completionHandler: { (request, response, JSON, error) in
            completionHandler(request, response, JSON, error)
        })
    }

    public class func ParsedJSONResponseSerializer() -> Serializer {
        return { (request, response, data) in
            if data == nil || data?.length == 0 {
                return (nil, nil)
            }

            let json = JSON(data: data!)
            if json.isError {
                return (nil, json.asError)
            }
            return (json, nil)
        }
    }
}