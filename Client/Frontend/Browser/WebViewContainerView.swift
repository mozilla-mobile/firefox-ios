/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

private let log = Logger.browserLogger

class WebViewContainerView: UIView {
    private let MAX_NUMBER_OF_WEB_VIEWS = 5

    private let toolbar = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(toolbar)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        toolbar.snp_makeConstraints { make in
            make.left.right.top.equalTo(self)
            make.height.equalTo(0)
        }
    }

    private func makeRoomForSubview() {
        if self.subviews.count > MAX_NUMBER_OF_WEB_VIEWS,
            let bottomWebView = ( self.subviews.find {
                $0.isKindOfClass(WKWebView)
                } ) {
                    log.info("Reached max number of WKWebViews in memory. Removing oldest view from container")
                    bottomWebView.removeFromSuperview()
        }
    }

    func addWebView(webView: WKWebView) {
        // if this webView is already on the stack, move it to the top
        if webView.superview == self {
            self.bringSubviewToFront(webView)
        }
        else {
            makeRoomForSubview()
            self.addSubview(webView)

            webView.snp_makeConstraints { make in
                make.top.equalTo(toolbar.snp_bottom)
                make.left.right.bottom.equalTo(self)
            }
        }
    }

    func insertWebView(webView: WKWebView, atIndex index: Int) {
        // if this webView is already on the stack, move it to the top
        makeRoomForSubview()
        self.insertSubview(webView, atIndex: index)

        webView.snp_makeConstraints { make in
            make.top.equalTo(toolbar.snp_bottom)
            make.left.right.bottom.equalTo(self)
        }
    }

    func addOpenInHelperView(view: UIView) {
        toolbar.addSubview(view)
        toolbar.snp_updateConstraints { make in
            make.height.equalTo(OpenInViewUX.ViewHeight)
        }
        view.snp_makeConstraints { make in
            make.edges.equalTo(toolbar)
        }
    }

    func removeOpenInHelperViews() {
        toolbar.subviews.forEach { $0.removeFromSuperview() }
        toolbar.snp_updateConstraints { make in
            make.height.equalTo(0)
        }
    }

    func showToolbar(show: Bool = true) {
        toolbar.hidden = !show
    }
}
