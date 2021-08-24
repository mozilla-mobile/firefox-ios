//
//  UIWindowExtensions.swift
//  Client
//
//  Created by Roux Buciu on 2021-08-23.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Foundation

extension UIWindow {
    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation
                .isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}
