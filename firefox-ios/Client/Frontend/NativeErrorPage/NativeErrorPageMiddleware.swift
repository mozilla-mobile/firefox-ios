// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared
import WebKit
import Security

@MainActor
final class NativeErrorPageMiddleware {
    private var nativeErrorPageHelper: NativeErrorPageHelper?
    private let windowManager: WindowManager

    init(windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.windowManager = windowManager
    }

    lazy var nativeErrorPageProvider: Middleware<AppState> = { [self] state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case NativeErrorPageActionType.receivedError:
            guard let action = action as? NativeErrorPageAction, let error = action.networkError else {return}
            nativeErrorPageHelper = NativeErrorPageHelper(error: error)
        case NativeErrorPageActionType.errorPageLoaded:
            self.initializeNativeErrorPage(windowUUID: windowUUID)
        case GeneralBrowserActionType.bypassCertificateWarning:
            Task { @MainActor in
                await self.handleBypassCertificateWarning(windowUUID: windowUUID)
            }

        default:
            break
        }
    }

    private func initializeNativeErrorPage(windowUUID: WindowUUID) {
        guard let helper = nativeErrorPageHelper else { return }
        let model = helper.parseErrorDetails()
        store.dispatch(
            NativeErrorPageAction(nativePageErrorModel: model,
                                  windowUUID: windowUUID,
                                  actionType: NativeErrorPageMiddlewareActionType.initialize)
        )
    }
    
    @MainActor
    private func handleBypassCertificateWarning(windowUUID: WindowUUID) async {
        guard
            let tabManager = try? windowManager.tabManager(for: windowUUID),
            let selectedTab = tabManager.selectedTab,
            let webView = selectedTab.webView,
            let error = nativeErrorPageHelper?.error,
            let failingURL = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL,
            let certChain = error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate],
            let cert = certChain.first,
            let host = failingURL.host
        else {
            return
        }

        let origin = "\(host):\(failingURL.port ?? 443)"
        selectedTab.profile.certStore.addCertificate(cert, forOrigin: origin)
        webView.replaceLocation(with: failingURL)
    }
}