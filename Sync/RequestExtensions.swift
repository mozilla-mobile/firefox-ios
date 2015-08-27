/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responseParsedJSON(partial: Bool, completionHandler: ResponseHandler) -> Self {
        let serializer = partial ? Request.PartialParsedJSONResponseSerializer() :
                                   Request.ParsedJSONResponseSerializer()
        return response(serializer: serializer, completionHandler: { (request, response, error) in
            completionHandler(request, response, error)
        })
    }

    public func responseParsedJSON(queue queue: dispatch_queue_t, partial: Bool, completionHandler: ResponseHandler) -> Self {
        let serializer = partial ? Request.PartialParsedJSONResponseSerializer() :
                                   Request.ParsedJSONResponseSerializer()
        return response(queue: queue, serializer: serializer, completionHandler: { (request, response, error) in
            completionHandler(request, response, error)
        })
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

private struct PartialParsedJSONResponseSerializer: ResponseSerializer {
    private var serializeResponse: (NSURLRequest?, NSHTTPURLResponse?, NSData?) -> Result<AnyObject>

    private init() {
        self.serializeResponse = { (request, response, data) in
            if data == nil || data?.length == 0 {
                return Result.Failure(nil, JSONSerializeError.NoData)
            }

            var err: NSError?
            let o: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &err)

            if let err = err {
                return (nil, err)
            }

            if (o == nil) {
                return (nil, nil)
            }

            let json = JSON(data: o!)
            if json.isError {
                return Result.Failure(nil, json.asError)
            }

            return Result.Success(json)
        }
    }
}
