// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

protocol NetworkRequest {
    func fetchDataForURL(_ url: URL, completion: @escaping ((Result<Data, SiteImageError>) -> Void))
}

class HTMLDataRequest: NetworkRequest {

    enum RequestConstants {
        static let timeout: TimeInterval = 5
        static let userAgent = ""
    }

    func fetchDataForURL(_ url: URL, completion: @escaping ((Result<Data, SiteImageError>) -> Void)) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["User-Agent": RequestConstants.userAgent]
        configuration.timeoutIntervalForRequest = RequestConstants.timeout

        let urlSession = URLSession(configuration: configuration)

        urlSession.dataTask(with: url) { data, _, error in
            guard let data = data,
                error != nil else {
                completion(.failure(.invalidHTML))
                return
            }
            completion(.success(data))
        }.resume()
    }
}
