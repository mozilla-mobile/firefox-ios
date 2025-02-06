// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class UnleashFeatureManagementSessionInitializer: FeatureManagementSessionInitializer {

    private let client: HTTPClient
    private let request: BaseRequest
    private var model: Unleash.Model
    var isSameModel: Bool = false

    public enum Error: Swift.Error {
        case network
        case noData
    }

    public init(client: HTTPClient, request: BaseRequest, model: Unleash.Model) {
        self.client = client
        self.request = request
        self.model = model
    }

    public func startSession<T: Decodable>() async throws -> T? {

        let (data, response) = try await client.perform(request)

        guard let response else {
            throw UnleashFeatureManagementSessionInitializer.Error.noData
        }

        switch response.statusCode {
        case 399...599:
            throw UnleashFeatureManagementSessionInitializer.Error.network
        case 304: // no changes reported by server -> return cached model
            var updatedModel = model
            updatedModel.updated = .init()
            return updatedModel as? T
        case 200:
            break
        default:
            throw UnleashFeatureManagementSessionInitializer.Error.noData
        }

        // read out Etag which identifies cached responses
        (response.allHeaderFields["Etag"] as? String).map { model.etag = $0 }

        guard let remoteToggles = try? JSONDecoder().decode(Unleash.FeatureResponse.self, from: data) else {
            return model as? T
        }

        model.toggles = Set(remoteToggles.toggles)
        return model as? T
    }
}
