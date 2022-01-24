/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Combine

final class InternalSettings: ObservableObject {
    let objectWillChange = PassthroughSubject<Void, Never>()

    @UserDefault(key: NimbusUseStagingServerDefault, defaultValue: false)
    var useStagingServer: Bool {
        willSet {
            objectWillChange.send()
        }
    }

    @UserDefault(key: NimbusUsePreviewCollectionDefault, defaultValue: false)
    var usePreviewCollection: Bool {
        willSet {
            objectWillChange.send()
        }
    }
}
