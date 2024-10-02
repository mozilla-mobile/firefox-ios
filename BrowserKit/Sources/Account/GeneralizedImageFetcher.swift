// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

public struct GeneralizedImageFetcher: URLCaching {
    public init() {}
    
    var urlSession = makeURLSession(
        userAgent: UserAgent.mobileUserAgent(),
        configuration: URLSessionConfiguration.default
    )

    public var urlCache: URLCache = {
        return URLCache.shared
    }()

    /// This method is a generalized image fetcher for images outside of favicons and Hero images. Please use
    /// `SiteImageView` for those image types.
    /// - Parameters:
    ///   - url: The location of the image to fetch.
    ///   - completion: The code block that will run on the `main` thread.
    public func getImageFor(
        url: URL,
        timestamp: Timestamp = Date.now(),
        completion: @escaping (UIImage?) -> Void
    ) {
        let request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 5
        )

        if let cachedImage = findCachedData(for: request, timestamp: timestamp) {
            DispatchQueue.main.async {
                completion(UIImage(data: cachedImage))
            }
        } else {
            fetchImage(request: request, completion: completion)
        }
    }

    private func fetchImage(
        request: URLRequest,
        completion: @escaping (UIImage?) -> Void
    ) {
        urlSession.dataTask(with: request) { data, response, error in
            guard error == nil else {
                DefaultLogger.shared.log(
                    "Error while attempting to fetch image! Error: \(String(describing: error?.localizedDescription))",
                    level: .debug,
                    category: .images
                )
                completion(nil)
                return
            }

            guard let response = validatedHTTPResponse(response, statusCode: 200..<300) else {
                DefaultLogger.shared.log("Bad response while attempting to fetch image!",
                                         level: .debug,
                                         category: .images)
                completion(nil)
                return
            }

            guard let data = data,
                  !data.isEmpty else {
                DefaultLogger.shared.log("Empty data received when attempting to fetch image!",
                                         level: .debug,
                                         category: .images)
                completion(nil)
                return
            }

            self.cache(response: response, for: request, with: data)

            DispatchQueue.main.async {
                completion(UIImage(data: data))
            }
        }.resume()
    }
}
