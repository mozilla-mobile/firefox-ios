/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Storage
import Shared

final class EcosiaImport {

    enum Status {
        case initial, succeeded, failed(Failure)
    }

    class Migration {
        var tabs: Status = .initial
        var favorites: Status = .initial
        var history: Status = .initial
    }

    struct Failure: Error {
        let reasons: [MaybeErrorType]
    }

    let profile: Profile
    let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    static var isNeeded: Bool {
        Core.User.shared.migrated != true
    }

    func migrate(finished: @escaping (Migration) -> ()) {
        let migration = Migration()

        // Migrate in order for performance reasons -> History, Favorites, Tabs
        EcosiaHistory.migrateLowLevel(Core.History().items, to: profile) { result in
            switch result {
            case .success:
                migration.history = .succeeded
            case .failure(let error):
                migration.history = .failed(error)
            }

            EcosiaFavourites.migrate(Core.Favourites().items, to: self.profile) { result in
                switch result {
                case .success:
                    migration.favorites = .succeeded
                case .failure(let error):
                    migration.favorites = .failed(error)
                }

                let urls = Core.Tabs().items.compactMap { $0.page?.url }
                EcosiaTabs.migrate(urls, to: self.tabManager) { result in
                    switch result {
                    case .success:
                        migration.tabs = .succeeded
                    case .failure(let error):
                        migration.tabs = .failed(error)
                    }

                    Core.User.shared.migrated = true
                    finished(migration)
                }
            }
        }
    }

}
