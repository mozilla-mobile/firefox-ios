// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Kingfisher
import Common

class DefaultSiteImageDownloader: ImageDownloader, SiteImageDownloader {
    var continuation: CheckedContinuation<SiteImageLoadingResult, Error>?
    var timeoutDelay: UInt64 { return 10 }
    var logger: Logger

    init(name: String = "default", logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(name: name)
    }

    func downloadImage(with url: URL,
                       completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?
    ) -> DownloadTask? {
        return downloadImage(with: url,
                             options: [.processor(SVGImageProcessor())],
                             completionHandler: { result in
            switch result {
            case .success(let value):
                completionHandler?(.success(value))
            case .failure(let error):
                completionHandler?(.failure(error))
            }
        })
    }
}
