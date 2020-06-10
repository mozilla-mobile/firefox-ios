//
//  ImageButtonWithLabel.swift
//  Client
//
//  Created by McNoor's  on 6/10/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import UIKit

class ImageButtonWithLabel: UIView {

    lazy var button = UIButton()
    lazy var label = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    func performLayout() {
        addSubview(button)
        addSubview(label)

        button.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self.safeAreaLayoutGuide)
            make.right.greaterThanOrEqualTo(self.safeAreaLayoutGuide).offset(30)
            make.left.greaterThanOrEqualTo(self.safeAreaLayoutGuide).inset(30)
            make.height.width.equalTo(60)
        }

        label.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalTo(self)
        }

        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
    }

    func addTarget(_ target: AnyObject?, action: Selector, forControlEvents events: UIControl.Event) {
        button.addTarget(target, action: action, for: events)
    }
}
