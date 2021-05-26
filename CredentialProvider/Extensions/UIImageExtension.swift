//
//  UIImageExtension.swift
//  CredentialProvider
//
//  Created by raluca.iordan on 5/18/21.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

extension UIImage {
    func tinted(_ color: UIColor) -> UIImage? {
           UIGraphicsBeginImageContextWithOptions(size, false, scale)
           defer { UIGraphicsEndImageContext() }
           color.set()
           draw(in: CGRect(origin: .zero, size: size))
           return UIGraphicsGetImageFromCurrentImageContext()
       }

       static func color(_ color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage? {
           UIGraphicsBeginImageContextWithOptions(size, false, 0)
           color.setFill()
           UIRectFill(CGRect(origin: CGPoint.zero, size: size))
           let image = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           return image
       }
}
