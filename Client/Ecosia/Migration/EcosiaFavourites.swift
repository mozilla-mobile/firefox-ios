/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Shared

final class EcosiaFavourites {
    static func migrate(_ favourites: [Page], to profile: Profile, progress: ((Double) -> ())? = nil, finished: @escaping (Result<[GUID], EcosiaImport.Failure>) -> ()){

        guard !favourites.isEmpty else {
            finished(.success([]))
            return
        }

        if let error = profile.places.reopenIfClosed() {
            finished(.failure(.init(reasons: [error])))
            return
        }

        let start = Date()
        let favImport = DispatchGroup()
        var errors = [MaybeErrorType]()
        var guids = [GUID]()

        for (i, page) in favourites.enumerated() {

            guard let urlString = page.urlString else { continue }
            
            favImport.enter()

            let bookmark = profile.places.createBookmark(parentGUID: "mobile______", url: urlString, title: page.title, position: nil)

            bookmark.uponQueue(.main) { guid in
                switch guid {
                case .success(let guid):
                    guids.append(guid)
                    // only report progress of every 20th bookmark as it's quick
                    if i % 20 == 0 {
                        progress?(Double(i) / Double(favourites.count))
                    }
                case .failure(let error):
                    errors.append(error)
                }
                favImport.leave()
            }
        }

        favImport.notify(queue: .main) {
            let duration = Date().timeIntervalSince(start)
            Analytics.shared.migrated(.favourites, in: duration)

            if errors.count > 0 {
                finished(.failure(.init(reasons: errors)))
            } else {
                finished(.success(guids))
            }
        }
    }

}

extension Core.Page {
    var urlString: String? {
        guard !(url.host == nil && url.scheme != nil) else { return nil }
        return url.scheme == nil ? "http://" + url.absoluteString : url.absoluteString
    }
}
