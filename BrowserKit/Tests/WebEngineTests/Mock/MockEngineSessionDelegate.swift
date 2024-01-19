// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockEngineSessionDelegate: EngineSessionDelegate {
    var onScrollChangeCalled = 0
    var onLongPressCalled = 0
    var onTitleChangeCalled = 0
    var onProgressCalled = 0
    var onNavigationStateChangeCalled = 0
    var onLoadingStateChangeCalled = 0

    var savedScrollX: Int?
    var savedScrollY: Int?
    var savedTouchPoint: CGPoint?
    var savedTitleChange: String?
    var savedProgressValue: Double?
    var savedCanGoBack: Bool?
    var savedCanGoForward: Bool?
    var savedLoading: Bool?

    func onScrollChange(scrollX: Int, scrollY: Int) {
        onScrollChangeCalled += 1
        savedScrollX = scrollX
        savedScrollY = scrollY
    }

    func onLongPress(touchPoint: CGPoint) {
        onLongPressCalled += 1
        savedTouchPoint = touchPoint
    }

    func onTitleChange(title: String) {
        onTitleChangeCalled += 1
        savedTitleChange = title
    }

    func onProgress(progress: Double) {
        onProgressCalled += 1
        savedProgressValue = progress
    }

    func onNavigationStateChange(canGoBack: Bool, canGoForward: Bool) {
        onNavigationStateChangeCalled += 1
        savedCanGoBack = canGoBack
        savedCanGoForward = canGoForward
    }

    func onLoadingStateChange(loading: Bool) {
        onLoadingStateChangeCalled += 1
        savedLoading = loading
    }
}
