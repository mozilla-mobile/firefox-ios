/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Shared

final class EcosiaFavourites {
    static func migrate(_ favourites: [Page], to profile: Profile, finished: @escaping (Result<[GUID], EcosiaImport.Failure>) -> ()){

        guard !favourites.isEmpty else {
            finished(.success([]))
            return
        }

        let favImport = DispatchGroup()
        var errors = [MaybeErrorType]()
        var guids = [GUID]()

        for page in favourites {

            favImport.enter()

            let bookmark = profile.places.createBookmark(parentGUID: "mobile______", url: page.url.absoluteString, title: page.title)

            bookmark.uponQueue(.main) { guid in
                switch guid {
                case .success(let guid):
                    guids.append(guid)
                case .failure(let error):
                    errors.append(error)
                }
                favImport.leave()
            }
        }

        favImport.notify(queue: .main) {
            if errors.count > 0 {
                finished(.failure(.init(reasons: errors)))
            } else {
                finished(.success(guids))
            }
        }
    }

}
