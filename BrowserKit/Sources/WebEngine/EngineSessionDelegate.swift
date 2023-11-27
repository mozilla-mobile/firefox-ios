// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol EngineSessionDelegate: AnyObject {
    func onScrollChange(scrollX: Int, scrollY: Int)
    func onLongPress(touchPoint: CGPoint)
    func onTitleChange(title: String)
    func onProgress(progress: Int)
    func onNavigationStateChange(canGoBack: Bool?, canGoForward: Bool?)
    func onLoadUrl()
}
