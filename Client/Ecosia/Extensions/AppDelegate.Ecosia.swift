// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Shared

extension AppDelegate {

    func startExperimentation() {
        Task {
            do {
                let env: Environment = AppConstants.BuildChannel == .release ? .production : .staging
                try await _ = Unleash.start(env: env)
            } catch {
                debugPrint(error)
            }
        }
    }

}
