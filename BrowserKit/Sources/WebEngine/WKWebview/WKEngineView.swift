// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class WKEngineView: UIView, EngineView, FullscreenDelegate {
    private var session: WKEngineSession?
    private var logger: Logger
    private var sessionlifeCycleManager: WKSessionLifecycleManager

    init(frame: CGRect,
         sessionlifeCycleManager: WKSessionLifecycleManager = DefaultWKSessionLifecycleManager(),
         logger: Logger = DefaultLogger.shared) {
        self.sessionlifeCycleManager = sessionlifeCycleManager
        self.logger = logger
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(session: EngineSession) {
        if let currentSession = self.session {
            remove(session: currentSession)
        }

        guard let session = session as? WKEngineSession else {
            logger.log("Adding a session that is not of type WKEngineSession in WKEngineView, that is not permitted",
                       level: .debug,
                       category: .webview)
            return
        }

        add(session: session)
    }

    private func remove(session: WKEngineSession) {
        session.webView.removeFromSuperview()
        session.fullscreenDelegate = nil
        sessionlifeCycleManager.deactivate(session)
    }

    private func add(session: WKEngineSession) {
        self.session = session
        session.fullscreenDelegate = self
        sessionlifeCycleManager.activate(session)
        setupWebViewLayout()
    }

    private func setupWebViewLayout() {
        guard let session else { return }

        let webView = session.webView
        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func enteringFullscreen() {
        guard let session else { return }

        let webView = session.webView
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func exitingFullscreen() {
        setupWebViewLayout()
    }
}
