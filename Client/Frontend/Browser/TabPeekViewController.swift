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

        if tab.webView == nil {
            tab.createWebview()
        }

        guard let webView = tab.webView else {
            print("Couldn't create web view!")
            return
        }

        self.view.addSubview(webView)
        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }
}
