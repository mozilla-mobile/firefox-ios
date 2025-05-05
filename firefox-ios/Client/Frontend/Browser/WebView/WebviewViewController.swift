// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import WebEngine
import Common

class WebviewViewController: UIViewController,
                             ContentContainable,
                             ScreenshotableView,
                             FullscreenDelegate {
    private var webView: WKWebView
    var contentType: ContentType = .webview
    // TODO: FXIOS-12158 Add back after investigating why video player is broken
//    var isFullScreen = false

    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }

    private func setupWebView() {
        view.addSubview(webView)
        webView.pinToSuperview()
    }

    func update(webView: WKWebView) {
        self.webView = webView

        // Avoid updating constraints while on fullscreen mode
        // TODO: FXIOS-12158 Add back after investigating why video player is broken
//        guard !isFullScreen else { return }
        setupWebView()
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

    // MARK: - FullscreenDelegate

    func enteringFullscreen() {
        // TODO: FXIOS-12158 Add back after investigating why video player is broken
//        isFullScreen = true
//        webView.translatesAutoresizingMaskIntoConstraints = true
//        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func exitingFullscreen() {
        // TODO: FXIOS-12158 Add back after investigating why video player is broken
//        setupWebView()
//        isFullScreen = false
    }
}
