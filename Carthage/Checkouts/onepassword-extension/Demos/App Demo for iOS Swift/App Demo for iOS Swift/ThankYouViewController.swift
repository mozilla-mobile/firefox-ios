//
//  ThankYouViewController.swift
//  App Demo for iOS Swift
//
//  Created by Rad on 2015-05-14.
//  Copyright (c) 2015 Agilebits. All rights reserved.
//

import Foundation

class ThankYouViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:UIStatusBarAnimation.None)
		self.view.backgroundColor = UIColor(patternImage: UIImage(named: "login-background.png")!)
	}
}
