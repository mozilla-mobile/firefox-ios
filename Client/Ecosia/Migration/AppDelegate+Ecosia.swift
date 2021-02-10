/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension AppDelegate {
    func migrateEcosiaContents() {
        guard EcosiaImport.isNeeded, let profile = profile else { return }

        let ecosiaImport = EcosiaImport(profile: profile, tabManager: self.tabManager)
        ecosiaImport.migrate { migration in
            if case let .failed(error) = migration.favorites {
                NSLog(error.localizedDescription)
            }
            if case let .failed(error) = migration.tabs {
                NSLog(error.localizedDescription)
            }
            if case let .failed(error) = migration.history {
                NSLog(error.localizedDescription)
            }
        }
    }
}
