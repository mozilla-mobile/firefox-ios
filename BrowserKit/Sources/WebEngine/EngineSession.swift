// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol EngineSession {
    func loadUrl(url: String)
    func stopLoading()
    func reload()
    func goBack()
    func goForward()
    func goToHistoryIndex(index: Int)
    func restoreState(state: Data)
    func close()
}
