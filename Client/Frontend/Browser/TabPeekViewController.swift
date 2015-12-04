//
//  TabViewController.swift
//  Client
//
//  Created by Emily Toop on 12/2/15.
//  Copyright © 2015 Mozilla. All rights reserved.
//

import UIKit

class TabPeekViewController: UIViewController {

    let tab: Browser

    init(tab: Browser) {
        self.tab = tab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // if there is no screenshot, load the URL in a web page
        // otherwise just show the screenshot
        guard let screenshot = tab.screenshot else {
            setupWebView(tab.url)
            return
        }
        setupWithScreenshot(screenshot)
    }

    private func setupWithScreenshot(screenshot: UIImage) {
        let imageView = UIImageView(image: screenshot)
        self.view.addSubview(imageView)

        imageView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    private func setupWebView(url: NSURL?) {
        let webView = WKWebView()
        self.view.addSubview(webView)

        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        if let url = url {
            webView.loadRequest(NSURLRequest(URL: url))
        }
    }
}
