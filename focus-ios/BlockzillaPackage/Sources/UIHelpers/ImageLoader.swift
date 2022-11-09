/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Combine

public class ImageLoader {
    private let cachedImages = NSCache<NSURL, UIImage>()
    private var runningRequests = [UUID: URLSessionDataTask]()
    private init() {}
    public static let shared = ImageLoader()
}

public extension ImageLoader {
    enum Error: Swift.Error {
        case missingImage
    }

    @discardableResult
    func loadImage(_ url: URL, _ completion: @escaping (Swift.Result<UIImage, Swift.Error>) -> Void) -> UUID? {

        if let image = cachedImages.object(forKey: url as NSURL) {
            completion(.success(image))
            return nil
        }

        let uuid = UUID()
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { self.runningRequests.removeValue(forKey: uuid) }

            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let data = data,
                let image = UIImage(data: data) {

                self.cachedImages.setObject(image, forKey: url as NSURL)
                completion(.success(image))
                return
            } else {
                completion(.failure(Error.missingImage))
                return
            }
        }
        task.resume()

        runningRequests[uuid] = task
        return uuid
    }

    func loadImage(_ url: URL) -> Future<UIImage, Swift.Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            self.loadImage(url) { result in
                promise(result)
            }
        }
    }

    func cancelLoad(_ uuid: UUID) {
        runningRequests[uuid]?.cancel()
        runningRequests.removeValue(forKey: uuid)
    }
}

public extension ImageLoader {
    func load(_ url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadImage(url) { result in
                continuation.resume(with: result)
            }
        }
    }
}
