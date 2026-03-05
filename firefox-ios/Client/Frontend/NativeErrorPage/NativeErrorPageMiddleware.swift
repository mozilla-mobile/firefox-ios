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
    private let logger: Logger

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.windowManager = windowManager
        self.logger = logger
    }

    lazy var nativeErrorPageProvider: Middleware<AppState> = { [self] state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case NativeErrorPageActionType.receivedError:
            guard
                let action = action as? NativeErrorPageAction,
                let error = action.networkError
            else { return }
            nativeErrorPageHelper = NativeErrorPageHelper(error: error)
        case NativeErrorPageActionType.errorPageLoaded:
            self.initializeNativeErrorPage(windowUUID: windowUUID)
        case NativeErrorPageActionType.bypassCertificateWarning:
            self.handleBypassCertificateWarning(windowUUID: windowUUID)

        default:
            break
        }
    }

    private func initializeNativeErrorPage(windowUUID: WindowUUID) {
        guard let helper = nativeErrorPageHelper else { return }
        let model = helper.parseErrorDetails()
        store.dispatch(
            NativeErrorPageAction(
                nativePageErrorModel: model,
                windowUUID: windowUUID,
                actionType: NativeErrorPageMiddlewareActionType.initialize
            )
        )
    }

    private func handleBypassCertificateWarning(windowUUID: WindowUUID) {
        let selectedTab: Tab?
        do {
            selectedTab = try windowManager.tabManager(for: windowUUID).selectedTab
        } catch {
            logger.log(
                "handleBypassCertificateWarning: Failed to fetch selected tab - \(String(describing: error))",
                level: .warning,
                category: .certificate
            )
            return
        }

        guard
            let selectedTab = selectedTab,
            let webView = selectedTab.webView,
            let certDetails = nativeErrorPageHelper?.getCertDetails()
        else {
            logger.log(
                "handleBypassCertificateWarning: Missing required data (tab, webView, cert)",
                level: .warning,
                category: .certificate
            )
            return
        }

        let origin = "\(certDetails.host):\(certDetails.failingURL.port ?? 443)"
        selectedTab.profile.certStore.addCertificate(certDetails.cert, forOrigin: origin)
        // Note: webview.reload will not change the error URL back to the original URL
        webView.replaceLocation(with: certDetails.failingURL)
    }
}
