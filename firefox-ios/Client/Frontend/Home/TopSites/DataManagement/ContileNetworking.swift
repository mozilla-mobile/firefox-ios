// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct ContileResultData {
    var data: Data
    var response: HTTPURLResponse
}

typealias NetworkingContileResult = Swift.Result<(ContileResultData), Error>

enum ContileNetworkingError: Error {
    case dataUnavailable
}

protocol ContileNetworking {
    func data(from request: URLRequest, completion: @escaping (NetworkingContileResult) -> Void)
}

class DefaultContileNetwork: ContileNetworking {
    private var urlSession: URLSessionProtocol
    private var logger: Logger

    init(with urlSession: URLSessionProtocol,
         logger: Logger = DefaultLogger.shared) {
        self.urlSession = urlSession
        self.logger = logger
    }

    func data(from request: URLRequest, completion: @escaping (NetworkingContileResult) -> Void) {
        urlSession.dataTaskWith(request: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.log("An error occurred while fetching data: \(error)",
                                level: .debug,
                                category: .legacyHomepage)
                completion(.failure(ContileNetworkingError.dataUnavailable))
                return
            }

            guard let response = validatedHTTPResponse(response, statusCode: 200..<300),
                  let data = data
            else {
                self.logger.log("Response isn't valid, data is nil?: \(data == nil)",
                                level: .debug,
                                category: .legacyHomepage)
                completion(.failure(ContileNetworkingError.dataUnavailable))
                return
            }

            completion(.success(ContileResultData(data: data, response: response)))
        }.resume()
    }
}
