//
//  WKWebViewExtensions.swift
//  Client
//
//  Created by Steph Leroux on 2015-05-08.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import WebKit
import UIKit

extension WKWebView {
    private func contentScreenshot(size: CGSize, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        assert(0...1 ~= quality)
        let offset = offset ?? CGPointMake(0, 0)

        let savedFrame = scrollView.frame
        scrollView.frame = CGRect(origin: offset, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale * quality)
        scrollView.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        scrollView.frame = savedFrame
        return image
    }

    func contentScreenshot(offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        let height = UIScreen.mainScreen().bounds.height * 2
        let size = CGSize(width: scrollView.contentSize.width, height: height)
        return self.contentScreenshot(size, offset: offset, quality: quality)
    }
}