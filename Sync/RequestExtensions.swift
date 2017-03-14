/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import SwiftyJSON

extension DataRequest {
    public func responsePartialParsedJSON(_ completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
        return response(responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responsePartialParsedJSON(queue: DispatchQueue, completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: partialParsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responseParsedJSON(_ partial: Bool, completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
        return response(responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }

    public func responseParsedJSON(queue: DispatchQueue, completionHandler: @escaping (DataResponse<JSON>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: parsedJSONResponseSerializer(), completionHandler: completionHandler)
    }
}

public enum JSONSerializeError: Error {
    case noData
    case parseError
}

private func parsedJSONResponseSerializer() -> DataResponseSerializer<JSON> {
    return DataResponseSerializer() { (request, response, data, error) -> Alamofire.Result<JSON> in
        guard let data = data, !data.isEmpty else {
            return .failure(JSONSerializeError.noData)
        }

        let json = JSON(data: data)
        if json.isError() {
            return .failure(JSONSerializeError.parseError)
        }

        return .success(json)
    }
}

private func partialParsedJSONResponseSerializer() -> DataResponseSerializer<JSON> {
    return DataResponseSerializer() { (request, response, data, error) -> Alamofire.Result<JSON> in
        guard let data = data, !data.isEmpty else {
            return .failure(JSONSerializeError.noData)
        }

        let o: Any?
        do {
            try o = JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            return .failure(JSONSerializeError.parseError)
        }

        guard let object = o else {
            return .failure(JSONSerializeError.noData)
        }

        let json = JSON(object)
        if json.isError() {
            return .failure(JSONSerializeError.parseError)
        }

        return .success(json)
    }
}
