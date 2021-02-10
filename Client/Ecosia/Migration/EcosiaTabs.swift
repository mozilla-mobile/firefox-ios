/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core

final class EcosiaTabs {

    static func migrate(_ urls: [URL], to tabManager: TabManager, finished: @escaping (Result<[Tab], EcosiaImport.Failure>) -> ()) {

        guard !urls.isEmpty else {
            finished(.success([]))
            return
        }

        let tabs = urls.map {
            tabManager.addTab(URLRequest(url: $0), flushToDisk: false, zombie: false)
        }

        let success = tabManager.storeChanges()
        success.uponQueue(.main) { result in
            switch result {
            case .success:
                finished(.success(tabs))
            case .failure(let error):
                finished(.failure(.init(reasons: [error])))
            }
        }
    }

}
