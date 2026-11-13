// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit
import WebKit

/// Full screen host for the bundled Fox Dash game, with a single native close button.
final class FoxDashViewController: UIViewController, Themeable {
    private enum UX {
        static var closeButtonPadding: CGFloat {
            if #available(iOS 26, *) {
                return 18.0
            }
            return 12.0
        }
    }

    // MARK: - Themeable
    let themeManager: ThemeManager
    var themeListenerCancellable: Any?
    let currentWindowUUID: WindowUUID?
    private let notificationCenter: NotificationProtocol

    private let themeProvider: FoxDashThemeProviding
    private let bundle: Bundle
    private let onClose: () -> Void

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "window.__FOX_DASH_THEME__ = \"\(themeProvider.themeID)\";",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        #if targetEnvironment(simulator)
        // Allow Safari Web Inspector only when running in simulator.
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        return webView
    }()

    private lazy var closeButton: UIButton = .build { [weak self] in
        $0.addAction(UIAction(handler: { _ in
            self?.onClose()
        }), for: .touchUpInside)
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?
            .withRenderingMode(.alwaysTemplate)
        $0.accessibilityLabel = .CloseButtonTitle
        $0.scalesLargeContentImage = true
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    init(
        windowUUID: WindowUUID,
        themeProvider: FoxDashThemeProviding = FoxDashThemeProvider(),
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        bundle: Bundle = .main,
        onClose: @escaping () -> Void
    ) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.themeProvider = themeProvider
        self.bundle = bundle
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: UX.closeButtonPadding
            ),
            closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: UX.closeButtonPadding
            )
        ])

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()

        guard let indexURL = bundle.url(forResource: "index", withExtension: "html", subdirectory: "FoxDash") else {
            onClose()
            return
        }
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer1
        if #unavailable(iOS 26.0) {
            closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
            closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        } else {
            closeButton.tintColor = theme.colors.iconPrimary
        }
    }
}
