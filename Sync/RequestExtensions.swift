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
        return response(serializer: serializer, completionHandler: { (request, response, JSON, error) in
            completionHandler(request, response, JSON, error)
        })
    }

    public func responseParsedJSON(queue queue: dispatch_queue_t, partial: Bool, completionHandler: ResponseHandler) -> Self {
        let serializer = partial ? Request.PartialParsedJSONResponseSerializer() :
                                   Request.ParsedJSONResponseSerializer()
        return response(queue: queue, serializer: serializer, completionHandler: { (request, response, JSON, error) in
            completionHandler(request, response, JSON, error)
        })
    }

    public class func PartialParsedJSONResponseSerializer() -> Serializer {
        return { (request, response, data) in
            if data == nil || data?.length == 0 {
                return (nil, nil)
            }

            var err: NSError?
            let o: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: &err)

            if let err = err {
                return (nil, err)
            }

            if (o == nil) {
                return (nil, nil)
            }

            let json = JSON(o!)
            if json.isError {
                return (nil, json.asError)
            }

            return (json, nil)
        }
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
