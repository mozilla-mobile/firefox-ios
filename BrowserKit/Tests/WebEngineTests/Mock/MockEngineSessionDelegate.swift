// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit.UIContextMenuConfiguration
@testable import WebEngine

class MockEngineSessionDelegate: EngineSessionDelegate {
    var onTitleChangeCalled = 0
    var onProgressCalled = 0
    var onNavigationStateChangeCalled = 0
    var onLoadingStateChangeCalled = 0
    var onLocationChangedCalled = 0
    var onHasOnlySecureContentCalled = 0
    var didLoadPagemetaDataCalled = 0
    var findInPageCalled = 0
    var searchCalled = 0
    var onProvideContextualMenuCalled = 0
    var onWillDisplayAcccessoryViewCalled = 0

    var savedTitleChange: String?
    var savedURL: String?
    var savedHasOnlySecureContent: Bool?
    var savedProgressValue: Double?
    var savedCanGoBack: Bool?
    var savedCanGoForward: Bool?
    var savedLoading: Bool?
    var savedPagemetaData: EnginePageMetadata?
    var savedFindInPageSelection: String?
    var savedSearchSelection: String?

    func onTitleChange(title: String) {
        onTitleChangeCalled += 1
        savedTitleChange = title
    }

    func onHasOnlySecureContentChanged(secure: Bool) {
        onHasOnlySecureContentCalled += 1
        savedHasOnlySecureContent = secure
    }

    func onLocationChange(url: String) {
        onLocationChangedCalled += 1
        savedURL = url
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

    func didLoad(pageMetadata: EnginePageMetadata) {
        didLoadPagemetaDataCalled += 1
        savedPagemetaData = pageMetadata
    }

    func findInPage(with selection: String) {
        findInPageCalled += 1
        savedFindInPageSelection = selection
    }

    func search(with selection: String) {
        searchCalled += 1
        savedSearchSelection = selection
    }

    func onProvideContextualMenu(linkURL: URL?) -> UIContextMenuConfiguration? {
        onProvideContextualMenuCalled += 1
        return nil
    }

    func onWillDisplayAccessoryView() -> EngineInputAccessoryView {
        onWillDisplayAcccessoryViewCalled += 1
        return .default
    }

    func adsSearchProviderModels() -> [EngineSearchProviderModel] {
        return MockAdsTelemetrySearchProvider.mockSearchProviderModels()
    }
}
