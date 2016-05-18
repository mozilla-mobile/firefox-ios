//
//  BackForwardTableViewCell.swift
//  Client
//
//  Created by Tyler Lacroix on 5/17/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit
import Storage

class BackForwardTableViewCell: UITableViewCell {
    
    struct BackForwardViewCellUX {
        static let bgColor = UIColor.init(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        static let faviconWidth = 20
        static let faviconPadding:CGFloat = 20
        static let labelPadding = 20
        static let borderSmall = 2
        static let borderBold = 5
        static let fontSize:CGFloat = 12.0
    }
    
    var faviconView: UIImageView!
    var label: UILabel!
    var bg: UIView!
    
    var connectingForwards = true
    var connectingBackwards = true
    
    var currentTab = false  {
        didSet {
            if(currentTab) {
                label.font = UIFont(name:"HelveticaNeue-Bold", size: BackForwardViewCellUX.fontSize)
                bg.snp_updateConstraints { make in
                    make.height.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderBold)
                    make.width.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderBold)
                }
            }
        }
    }
    
    var site: Site? {
        didSet {
            if let s = site {
                faviconView.setIcon(s.icon, withPlaceholder: FaviconFetcher.defaultFavicon)
                label.text = s.title
                setNeedsLayout()
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clearColor()
        selectionStyle = .None
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.redColor()
        selectedBackgroundView =  selectedView;
        
        faviconView = UIImageView(image: FaviconFetcher.defaultFavicon)
        faviconView.backgroundColor = UIColor.whiteColor()
        contentView.addSubview(faviconView)
        
        label = UILabel(frame: CGRectZero)
        label.textColor = UIColor.blackColor()
        label.text = " "
        label.font = label.font.fontWithSize(BackForwardViewCellUX.fontSize)
        contentView.addSubview(label)
        
        faviconView.snp_makeConstraints { make in
            make.height.equalTo(BackForwardViewCellUX.faviconWidth)
            make.width.equalTo(BackForwardViewCellUX.faviconWidth)
            make.centerY.equalTo(self)
            make.left.equalTo(self.snp_left).offset(BackForwardViewCellUX.faviconPadding)
        }
        
        label.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.left.equalTo(faviconView.snp_right).offset(BackForwardViewCellUX.labelPadding)
            make.right.equalTo(self.snp_right).offset(BackForwardViewCellUX.labelPadding)
        }
        
        bg = UIView(frame: CGRect.zero)
        bg.backgroundColor = BackForwardViewCellUX.bgColor
        
        self.addSubview(bg)
        self.sendSubviewToBack(bg)
        
        bg.snp_makeConstraints { make in
            make.height.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
            make.width.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
            make.centerX.equalTo(faviconView)
            make.centerY.equalTo(faviconView)
        }
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext();
        
        let startPoint = CGPointMake(rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5),
                                     rect.origin.y + (connectingForwards ?  0 : rect.size.height/2))
        let endPoint   = CGPointMake(rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5),
                                     rect.origin.y + rect.size.height - (connectingBackwards  ? 0 : rect.size.height/2))
        
        CGContextSaveGState(context)
        CGContextSetLineCap(context, CGLineCap.Square)
        CGContextSetStrokeColorWithColor(context, BackForwardViewCellUX.bgColor.CGColor)
        CGContextSetLineWidth(context, 1.0)
        CGContextMoveToPoint(context, startPoint.x, startPoint.y)
        CGContextAddLineToPoint(context, endPoint.x, endPoint.y)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if (highlighted) {
            self.backgroundColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.1)
        }
        else {
            self.backgroundColor = UIColor.clearColor()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        connectingForwards = true
        connectingBackwards = true
        currentTab = false
        label.font = UIFont(name:"HelveticaNeue", size: BackForwardViewCellUX.fontSize)
        
        bg.snp_updateConstraints { make in
            make.height.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
            make.width.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
        }
    }
}