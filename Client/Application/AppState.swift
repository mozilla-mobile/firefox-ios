/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol AppStateDelegate: class {
    func appDidUpdateState(appState: AppState)
}

protocol StateProvider {
    var state: AppState { get set }
}

protocol AppState: State {
    var isPrivate: Bool { get set }
}
