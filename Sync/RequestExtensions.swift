/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responsePartialParsedJSON(_ completionHandler: (Response<JSON, JSONSerializeError>) -> ()) -> Self {
        return self.response(responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responsePartialParsedJSON(queue: DispatchQueue, completionHandler: (Response<JSON, JSONSerializeError>) -> ()) -> Self {
        return self.response(queue: queue, responseSerializer: partialParsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responseParsedJSON(_ partial: Bool, completionHandler: (Response<JSON, JSONSerializeError>) -> ()) -> Self {
        return self.response(responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responseParsedJSON(queue: DispatchQueue, completionHandler: (Response<JSON, JSONSerializeError>) -> ()) -> Self {
        return self.response(queue: queue, responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }
}

public enum JSONSerializeError: Error {
    case noData
    case parseError
}

private func parsedJSONResponseSerializer() -> ResponseSerializer<JSON, JSONSerializeError> {
    return ResponseSerializer() { (request, response, data, error) -> Alamofire.Result<JSON, JSONSerializeError> in
        if data == nil || data?.length == 0 {
            return Result.Failure(JSONSerializeError.NoData)
        }

        let json = JSON(data: data!)
        if json.isError {
            return Result.Failure(JSONSerializeError.ParseError)
        }

        return Result.Success(json)
    }
}

private func partialParsedJSONResponseSerializer() -> ResponseSerializer<JSON, JSONSerializeError> {
    return ResponseSerializer() { (request, response, data, error) -> Alamofire.Result<JSON, JSONSerializeError> in
        if data == nil || data?.length == 0 {
            return Result.Failure(JSONSerializeError.NoData)
        }

        let o: AnyObject?
        do {
            try o = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
        } catch {
            return Result.Failure(JSONSerializeError.ParseError)
        }

        guard let object = o else {
            return Result.Failure(JSONSerializeError.NoData)
        }

        let json = JSON(object)
        if json.isError {
            return Result.Failure(JSONSerializeError.ParseError)
        }

        return Result.Success(json)
    }
}
