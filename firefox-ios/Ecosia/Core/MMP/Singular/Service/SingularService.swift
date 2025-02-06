// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

#if os(iOS)

protocol SingularNotificationRequest: BaseRequest {}
extension SingularSessionInfoSendRequest: SingularNotificationRequest {}
extension SingularEventRequest: SingularNotificationRequest {}

protocol SingularServiceProtocol {
    func sendNotification(request: SingularNotificationRequest) async throws
    func getConversionValue(request: SingularConversionValueRequest) async throws -> SingularConversionValueResponse
}

final class SingularService: SingularServiceProtocol {

    enum Error: Swift.Error {
        case network
        case dataReturnedError(reason: String)
        case noConversionValueReturned
    }

    let client: HTTPClient

    init(client: HTTPClient = URLSessionHTTPClient()) {
        self.client = client
    }

    func sendNotification(request: SingularNotificationRequest) async throws {
        let (data, response) = try await client.perform(request)
        guard let response, response.statusCode == 200 else {
            throw SingularService.Error.network
        }

        let dataResult = try JSONDecoder().decode(SingularResponse.self, from: data)

        guard dataResult.isOK, dataResult.errorReason == nil else {
            throw SingularService.Error.dataReturnedError(reason: dataResult.errorReason ?? "")
        }
    }

    func getConversionValue(request: SingularConversionValueRequest) async throws -> SingularConversionValueResponse {
        let (data, response) = try await client.perform(request)

        guard let response, response.statusCode == 200 else {
            throw SingularService.Error.network
        }

        do {
            return try JSONDecoder().decode(SingularConversionValueResponse.self, from: data)
        } catch DecodingError.keyNotFound {
            let fallbackResponse = try JSONDecoder().decode(SingularResponse.self, from: data)
            if !fallbackResponse.isOK {
                throw Error.dataReturnedError(reason: fallbackResponse.errorReason ?? "")
            }
            throw Error.noConversionValueReturned // Likely due to no conversion model active for the app
        }
    }
}

#endif
