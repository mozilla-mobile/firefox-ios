//
//  Animatable.swift
//  Client
//
//  Created by Emily Toop on 08/04/2016.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

protocol Animatable {
    func animateFromView(view: UIView, offset: CGFloat?, completion: ((Bool) -> Void)?)
}
