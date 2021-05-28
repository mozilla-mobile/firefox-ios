//
//  UIColorExtension.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/18/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red: (hex >> 16) & 0xff, green: (hex >> 8) & 0xff, blue: hex & 0xff)
    }
    
    static let cellBorderGrey = UIColor(hex: 0xC8C7CC)
    static let viewBackground = UIColor(hex: 0xEDEDF0)
    static let lightGrey = UIColor(hex: 0xEFEFEF)
    static let systemLightGray = UIColor.lightGray
    static let lockBoxViolet = UIColor(red: 89, green: 42, blue: 203)
    static let lockBoxTeal = UIColor(hex: 0x00C8D7)
    static let settingsHeader = UIColor(hex: 0x737373)
    static let tableViewCellHighlighted = UIColor(red: 231, green: 223, blue: 255)
    static let buttonTitleColorNormalState = UIColor.white
    static let buttonTitleColorOtherState = UIColor(white: 1.0, alpha: 0.6)
    static let shadowColor = UIColor(red: 12, green: 12, blue: 13)
    static let videoBorderColor = UIColor(hex: 0xD7D7DB)
    static let helpTextBorderColor = UIColor(hex: 0xD8D7DE)
    static let navBackgroundColor = UIColor(red: 57, green: 52, blue: 115)
    static let navTextColor = UIColor(red: 237, green: 237, blue: 240)
    static let inactiveNavSearchBackgroundColor = UIColor(red: 43, green: 33, blue: 86)
    static let activeNavSearchBackgroundColor = UIColor(red: 39, green: 25, blue: 72)
    static let navSerachTextColor = UIColor.white
    static let navSearchPlaceholderTextColor = UIColor(white: 1.0, alpha: 0.8)
    static let disabledButtonTextColor = UIColor(red: 0.6119456291, green: 0.590236485, blue: 0.6646512747, alpha: 1)
    static let disabledButtonBackgroundColor = UIColor(red: 0.9608519673, green: 0.9606127143, blue: 0.9735968709, alpha: 1)
}
