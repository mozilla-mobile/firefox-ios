// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import ScreenTime

class WebviewViewController: UIViewController, ContentContainable, ScreenshotableView {
    private var webView: WKWebView
    private let screenTimeController = STWebpageController()
    var contentType: ContentType = .webview

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
        setupScreenTimeController()
    }

    private func setupWebView() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
    }

    private func setupScreenTimeController() {
        addChild(screenTimeController)
        view.addSubview(screenTimeController.view)
        screenTimeController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            screenTimeController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            screenTimeController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            screenTimeController.view.topAnchor.constraint(equalTo: view.topAnchor),
            screenTimeController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        screenTimeController.didMove(toParent: self)
        screenTimeController.url = webView.url
    }

    func update(webView: WKWebView) {
        self.webView = webView
        setupWebView()
        setupScreenTimeController()
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
