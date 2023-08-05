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

    init(webView: WKWebView, isPrivate: Bool = false) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        setScreenTimeUsage(isPrivate: isPrivate)
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

    func update(webView: WKWebView, isPrivate: Bool = false) {
        removeWebview()
        self.webView = webView
        setupWebView()
        setupScreenTimeController()
        setScreenTimeUsage(isPrivate: isPrivate)
    }

    private func removeWebview() {
        webView.removeFromSuperview()
    }

    // MARK: - Rotation
    /// Screentime needs to be added on top of a webview to work, but on rotation it results in a black flash #15432
    /// We remove it on rotation and then add it back when rotation is done to solve this issue

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        prepareForRotation()

        coordinator.animate(alongsideTransition: nil) { _ in
            self.rotationEnded()
        }
    }

    private func prepareForRotation() {
        removeScreenTimeController()
    }

    private func rotationEnded() {
        setupScreenTimeController()
    }

    // MARK: - ScreenTime

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

    private func removeScreenTimeController() {
        screenTimeController.willMove(toParent: nil)
        screenTimeController.view.removeFromSuperview()
        screenTimeController.removeFromParent()
    }

    private func setScreenTimeUsage(isPrivate: Bool) {
        // Usage recording is suppressed if the navigation is set to incognito mode.
        screenTimeController.suppressUsageRecording = isPrivate
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
