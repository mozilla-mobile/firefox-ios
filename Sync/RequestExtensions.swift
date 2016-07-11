/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared

extension Request {
    public func responsePartialParsedJSON(_ completionHandler: ResponseHandler) -> Self {
        let serializer = PartialParsedJSONResponseSerializer()
        return self.response(responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responsePartialParsedJSON(queue: DispatchQueue, completionHandler: ResponseHandler) -> Self {
        let serializer = PartialParsedJSONResponseSerializer()
        return self.response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responseParsedJSON(_ partial: Bool, completionHandler: ResponseHandler) -> Self {
        let serializer = ParsedJSONResponseSerializer()
        return self.response(responseSerializer: serializer, completionHandler: completionHandler)
    }

    public func responseParsedJSON(queue: DispatchQueue, completionHandler: ResponseHandler) -> Self {
        let serializer = ParsedJSONResponseSerializer()
        return self.response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
    }
}

private enum JSONSerializeError: ErrorProtocol {
    case noData
    case parseError
}

private struct ParsedJSONResponseSerializer: ResponseSerializer {
    private var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?) -> Result<AnyObject>

    private init() {
        self.serializeResponse = { (request, response, data) in
            if data == nil || data?.count == 0 {
                return Result.failure(nil, JSONSerializeError.noData)
            }

            let json = JSON(data: data!)
            if json.isError {
                return Result.failure(data, JSONSerializeError.parseError)
            }

            return Result.Success(json)
        }
    }
}

private struct PartialParsedJSONResponseSerializer: ResponseSerializer {
    private var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?) -> Result<AnyObject>

    private init() {
        self.serializeResponse = { (request, response, data) in
            if data == nil || data?.count == 0 {
                return Result.failure(nil, JSONSerializeError.noData)
            }

            let o: AnyObject?
            do {
                try o = JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
            } catch {
                return Result.failure(nil, error)
            }

            guard let object = o else {
                return Result.failure(nil, JSONSerializeError.noData)
            }

            let json = JSON(object)
            if json.isError {
                return Result.Failure(nil, json.asError ?? JSONSerializeError.ParseError)
            }

            return Result.Success(json)
        }
    }
}
