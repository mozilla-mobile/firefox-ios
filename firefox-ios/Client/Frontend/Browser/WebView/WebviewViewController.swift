// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import Common

class WebviewViewController: UIViewController,
                             ContentContainable,
                             ScreenshotableView,
                             Themeable,
                             InjectedThemeUUIDIdentifiable {
    private struct UX {
        static let documentLoadingViewAnimationDuration: CGFloat = 0.3
    }
    private var documentLoadingView: TemporaryDocumentLoadingView?
    private var webView: WKWebView
    var contentType: ContentType = .webview
    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: WindowUUID? {
        return windowUUID
    }

    init(webView: WKWebView,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.webView = webView
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        listenForThemeChange(view)
    }

    private func setupWebView() {
        view.addSubview(webView)
        webView.pinToSuperview()
    }

    func update(webView: WKWebView) {
        self.webView = webView
        setupWebView()
        guard let documentLoadingView else { return }
        view.bringSubviewToFront(documentLoadingView)
    }

    func showDocumentLoadingView() {
        guard documentLoadingView == nil else { return }
        let documentLoadingView = TemporaryDocumentLoadingView(frame: view.bounds)
        documentLoadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(documentLoadingView)
        documentLoadingView.pinToSuperview()

        documentLoadingView.animateLoadingAppearanceIfNeeded()
        self.documentLoadingView = documentLoadingView
        applyTheme()
    }

    func removeDocumentLoadingView(completion: (() -> Void)? = nil) {
        guard let documentLoadingView else { return }
        UIView.animate(withDuration: UX.documentLoadingViewAnimationDuration) {
            documentLoadingView.alpha = 0.0
        } completion: { _ in
            documentLoadingView.removeFromSuperview()
            self.documentLoadingView = nil
            completion?()
        }
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        documentLoadingView?.applyTheme(theme: theme)
    }

    // MARK: - ScreenshotableView

    func getScreenshotData(completionHandler: @escaping (ScreenshotData?) -> Void) {
        guard let url = webView.url,
              InternalURL(url) == nil else {
            completionHandler(nil)
            return
        }

        var rect = webView.scrollView.frame
        rect.origin.x = webView.scrollView.contentOffset.x
        rect.origin.y = webView.scrollView.contentSize.height - rect.height - webView.scrollView.contentOffset.y

        webView.createPDF { result in
            switch result {
            case .success(let data):
                completionHandler(ScreenshotData(pdfData: data, rect: rect))
            case .failure:
                completionHandler(nil)
            }
        }
    }
}
