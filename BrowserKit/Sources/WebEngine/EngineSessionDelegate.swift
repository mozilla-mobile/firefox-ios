// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Delegate used by the class that want to observe an engine session
public protocol EngineSessionDelegate: AnyObject {
    /// Event to indicate the scroll position of the content has changed.
    func onScrollChange(scrollX: Int, scrollY: Int)

    /// Event to indicate that this session has had a long press.
    func onLongPress(touchPoint: CGPoint)

    /// Event to indicate the title has changed.
    func onTitleChange(title: String)

    /// Event to indicate the loading progress has been updated.
    func onProgress(progress: Int)

    /// Event to indicate there has been a navigation change.
    func onNavigationStateChange(canGoBack: Bool?, canGoForward: Bool?)

    /// Event to indicate that a url was loaded to this session.
    func onLoadUrl()
}
