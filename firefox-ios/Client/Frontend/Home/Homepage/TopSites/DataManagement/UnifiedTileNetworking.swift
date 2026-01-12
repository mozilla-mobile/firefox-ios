// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct UnifiedTileResultData {
    let data: Data
    let response: HTTPURLResponse
}

typealias NetworkingUnifiedTileResult = Swift.Result<(UnifiedTileResultData), UnifiedTileNetworkingError>

enum UnifiedTileNetworkingError: Error {
    case dataUnavailable
}

protocol UnifiedTileNetworking: Sendable {
    func data(from request: URLRequest, completion: @escaping @Sendable (NetworkingUnifiedTileResult) -> Void)
}

final class DefaultUnifiedTileNetwork: UnifiedTileNetworking {
    private let urlSession: URLSessionProtocol
    private let logger: Logger

    init(with urlSession: URLSessionProtocol,
         logger: Logger = DefaultLogger.shared) {
        self.urlSession = urlSession
        self.logger = logger
    }

    func data(from request: URLRequest, completion: @escaping @Sendable (NetworkingUnifiedTileResult) -> Void) {
        urlSession.dataTaskWith(request: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.log("An error occurred while fetching data: \(error)",
                                level: .debug,
                                category: .homepage)
                completion(.failure(UnifiedTileNetworkingError.dataUnavailable))
                return
            }

            guard let response = validatedHTTPResponse(response, statusCode: 200..<300),
                  let data = data
            else {
                self.logger.log("Response isn't valid, data is nil?: \(data == nil)",
                                level: .debug,
                                category: .homepage)
                completion(.failure(UnifiedTileNetworkingError.dataUnavailable))
                return
            }

            completion(.success(UnifiedTileResultData(data: data, response: response)))
        }.resume()
    }
}
