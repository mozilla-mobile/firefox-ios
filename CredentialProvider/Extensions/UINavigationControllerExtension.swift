//
//  UINavigationControllerExtension.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/18/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func iosThirteenNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = UIColor.navBackgroundColor
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
}
