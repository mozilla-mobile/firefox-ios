/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responsePartialParsedJSON(completionHandler: ResponseHandler) -> Self {
        let serializer = PartialParsedJSONResponseSerializer()
        return self.response(responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responsePartialParsedJSON(queue queue: dispatch_queue_t, completionHandler: ResponseHandler) -> Self {
        let serializer = PartialParsedJSONResponseSerializer()
        return self.response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responseParsedJSON(partial: Bool, completionHandler: ResponseHandler) -> Self {
        let serializer = ParsedJSONResponseSerializer()
        return self.response(responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responseParsedJSON(queue queue: dispatch_queue_t, completionHandler: ResponseHandler) -> Self {
        let serializer = ParsedJSONResponseSerializer()
        return self.response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
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

            let o: AnyObject?
            do {
                try o = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            } catch {
                return Result.Failure(nil, error)
            }

            guard let object = o else {
                return Result.Failure(nil, JSONSerializeError.NoData)
            }

            let json = JSON(object)
            if json.isError {
                return Result.Failure(nil, json.asError ?? JSONSerializeError.ParseError)
            }

            return Result.Success(json)
        }
    }
}
