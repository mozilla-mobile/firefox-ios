// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Common
import Shared

class PrivacyPolicyViewController: UIViewController, Themeable {
    private enum UX {
        static let leadingPaddingPad: CGFloat = 8
        static let leadingPaddingPhone: CGFloat = 0
        static let topPaddingPad: CGFloat = 0
        static let topPaddingPhone: CGFloat = 0
        static let contentScalePhone: CGFloat = 1.0
        static var contentScaleIpad: CGFloat {
            if UIWindow.isPortrait {
                return 0.84
            } else {
                return 0.58
            }
        }
    }
    private var webView: WKWebView!
    private var url: URL
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    init(
        url: URL,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.url = url
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupView()
        applyTheme()
    }

    func setupView() {
        var frame = CGRect(x: UX.leadingPaddingPhone,
                           y: UX.topPaddingPhone,
                           width: view.frame.width,
                           height: view.frame.height)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if traitCollection.horizontalSizeClass == .regular {
                frame = CGRect(x: UX.leadingPaddingPad,
                               y: UX.topPaddingPad,
                               width: view.frame.width * UX.contentScaleIpad,
                               height: view.frame.height - UX.topPaddingPad)
            } else {
                frame = CGRect(x: UX.leadingPaddingPhone,
                               y: UX.topPaddingPhone,
                               width: view.frame.width * UX.contentScalePhone,
                               height: view.frame.height - UX.topPaddingPhone)
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            frame = CGRect(x: UX.leadingPaddingPhone,
                           y: UX.topPaddingPhone,
                           width: view.frame.width * UX.contentScalePhone,
                           height: view.frame.height - UX.topPaddingPhone)
        }
        webView = WKWebView(frame: frame)
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        view.backgroundColor = .systemBackground
        view.addSubview(webView)
    }

    // MARK: - Theming
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.actionPrimary
    }
}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let contentSize = webView.scrollView.contentSize
        let viewSize = self.view.bounds.size
        let zoom = viewSize.width / contentSize.width

        webView.scrollView.minimumZoomScale = zoom * 0.8
        webView.scrollView.maximumZoomScale = zoom * 0.8
        webView.scrollView.zoomScale = zoom * 0.8
    }
}
