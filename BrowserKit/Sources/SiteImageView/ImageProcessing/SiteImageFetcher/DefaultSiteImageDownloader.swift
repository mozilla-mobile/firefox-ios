// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Kingfisher

class DefaultSiteImageDownloader: ImageDownloader, SiteImageDownloader {
    var timer: Timer?
    var timeoutDelay: Double { return 1 }

    // TODO: Laurie - test, with injection
    override init(name: String = "default") {
        super.init(name: name)
    }

    func createTimer(completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?) {
        self.timer = Timer.scheduledTimer(withTimeInterval: timeoutDelay,
                                          repeats: false) { _ in
            completionHandler?(.failure(SiteImageError.unableToDownloadImage("Timeout reached")))
        }
    }

    func downloadImage(with url: URL,
                       completionHandler: ((Result<SiteImageLoadingResult, Error>) -> Void)?
    ) -> DownloadTask? {
        createTimer(completionHandler: completionHandler)

        return downloadImage(with: url,
                             options: nil,
                             completionHandler: { result in
            // laurie
//            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard self.shouldContinue else { return }

                switch result {
                case .success(let value):
                    completionHandler?(.success(value))
                case .failure(let error):
                    completionHandler?(.failure(error))
                }
//            }
        })
    }
}
