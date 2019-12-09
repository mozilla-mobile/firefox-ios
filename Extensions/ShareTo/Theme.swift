//
//  Theme.swift
//  ShareTo
//
//  Created by YUSA DOGRU on 9.12.2019.
//  Copyright © 2019 Mozilla. All rights reserved.
//

import UIKit

extension UIColor {
    static var theme: Theme {
        return ThemeManager.instance.current
    }
}

class ThemeManager {
    static let instance = ThemeManager()
    var current: Theme = NormalTheme()
}

protocol Theme {
    var doneLabelBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
    var actionRowTextAndIconColor: UIColor { get }
    var defaultBackground: UIColor { get }
}

class NormalTheme: Theme {
    var defaultBackground = UIColor.white
    var doneLabelBackgroundColor = UIColor.Photon.Blue40
    var separatorColor = UIColor.Photon.Grey30
    var actionRowTextAndIconColor = UIColor.Photon.Grey80
}

class DarkTheme: Theme {
    var defaultBackground = UIColor.Photon.Grey80
    var doneLabelBackgroundColor = UIColor.Photon.Blue40
    var separatorColor = UIColor.Photon.Grey10
    var actionRowTextAndIconColor = UIColor.white
}
