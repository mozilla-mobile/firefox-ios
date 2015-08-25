/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responseParsedJSON(completionHandler: ResponseHandler) -> Self {
        return response(responseSerializer: ParsedJSONResponseSerializer()) { (request, response, result) in
            completionHandler(request, response, result)
        }
    }

    public func responseParsedJSON(queue queue: dispatch_queue_t, completionHandler: ResponseHandler) -> Self {
        return response(queue: queue, responseSerializer: ParsedJSONResponseSerializer()) { (request, response, result) in
            completionHandler(request, response, result)
        }
    }
}

private enum JSONSerializeError: ErrorType {
    case NoData
    case ParseError
}

private struct ParsedJSONResponseSerializer: ResponseSerializer {
    private var serializeResponse: (NSURLRequest?, NSHTTPURLResponse?, NSData?) -> Result<AnyObject>

    private init() {
        self.serializeResponse = { (request, response, data) in
            if data == nil || data?.length == 0 {
                return Result.Failure(nil, JSONSerializeError.NoData)
            }

            let json = JSON(data: data!)
            if json.isError {
                return Result.Failure(data, JSONSerializeError.ParseError)
            }

            return Result.Success(json)
        }
    }
}