//
//  UndoToast.swift
//  Client
//
//  Created by Tyler Lacroix on 5/16/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit


private struct ToastUX {
    static let backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
    static let backgroundBorderColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    static let backgroundBorderWidth: CGFloat = 1
    static let messageColor = UIColor.blackColor()
    static let maxWidthPercentage: CGFloat = 0.8
    static let maxHeightPercentage: CGFloat = 0.8
    static let horizontalPadding: CGFloat = 14.0
    static let verticalPadding: CGFloat = 14.0
    static let cornerRadius: CGFloat = 5.0;
    static let messageFont = UIFont.systemFontOfSize(16.0)
    static let messageAlignment = NSTextAlignment.Left
    static let messageNumberOfLines = 0;
    static let activitySize = CGSize(width: 100.0, height: 100.0)
    static let fadeDuration: NSTimeInterval = 0.2
    
}

class UndoToast: UIView {
    
    init() {
        var messageLabel: UILabel?
        
        let wrapperView = UIView()
        wrapperView.userInteractionEnabled = false
        wrapperView.backgroundColor = ToastUX.backgroundColor
        wrapperView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        wrapperView.layer.cornerRadius = ToastUX.cornerRadius
        wrapperView.layer.borderColor = ToastUX.backgroundBorderColor.CGColor
        wrapperView.layer.borderWidth = ToastUX.backgroundBorderWidth
        
        messageLabel = UILabel()
        messageLabel?.userInteractionEnabled = false
        messageLabel?.text = "Tabs closed." + " |  " + "Undo"
        messageLabel?.numberOfLines = ToastUX.messageNumberOfLines
        messageLabel?.font = ToastUX.messageFont
        messageLabel?.textAlignment = ToastUX.messageAlignment
        messageLabel?.lineBreakMode = .ByTruncatingTail;
        messageLabel?.textColor = ToastUX.messageColor
        messageLabel?.backgroundColor = UIColor.clearColor()
        
        let maxMessageSize = CGSize(width: (500 * ToastUX.maxWidthPercentage), height: 500 * ToastUX.maxHeightPercentage)
        let messageSize = messageLabel?.sizeThatFits(maxMessageSize)
        if let messageSize = messageSize {
            let actualWidth = min(messageSize.width, maxMessageSize.width)
            let actualHeight = min(messageSize.height, maxMessageSize.height)
            messageLabel?.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
        }
        
        var messageRect = CGRectZero
        
        if let messageLabel = messageLabel {
            messageRect.origin.x = ToastUX.horizontalPadding
            messageRect.origin.y = ToastUX.verticalPadding
            messageRect.size.width = messageLabel.bounds.size.width
            messageRect.size.height = messageLabel.bounds.size.height
        }
        
        let longerWidth = messageRect.size.width
        let longerX = messageRect.origin.x
        let wrapperWidth = max((ToastUX.horizontalPadding * 2.0), (longerX + longerWidth + ToastUX.horizontalPadding))
        let wrapperHeight = max((messageRect.origin.y + messageRect.size.height + ToastUX.verticalPadding), (ToastUX.verticalPadding * 2.0))
        
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: wrapperWidth, height: wrapperHeight)
        
        if let messageLabel = messageLabel {
            messageLabel.frame = messageRect
            wrapperView.addSubview(messageLabel)
        }
        
        super.init(frame: wrapperView.frame)
        
        snp_makeConstraints { make in
            make.height.equalTo(wrapperHeight)
            make.width.equalTo(wrapperWidth)
        }
        
        self.addSubview(wrapperView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
