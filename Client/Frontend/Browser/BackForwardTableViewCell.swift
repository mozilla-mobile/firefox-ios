/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class BackForwardTableViewCell: UITableViewCell {
    
    struct BackForwardViewCellUX {
        static let bgColor = UIColor(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        static let faviconWidth = 20
        static let faviconPadding:CGFloat = 20
        static let labelPadding = 20
        static let borderSmall = 2
        static let borderBold = 5
        static let fontSize:CGFloat = 12.0
    }
    
    lazy var faviconView: UIImageView = {
        let faviconView = UIImageView(image: FaviconFetcher.defaultFavicon)
        faviconView.backgroundColor = UIColor.whiteColor()
        return faviconView
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = label.font.fontWithSize(BackForwardViewCellUX.fontSize)
        return label
    }()
    
    lazy var bg: UIView = {
        let bg = UIView(frame: CGRect.zero)
        bg.backgroundColor = BackForwardViewCellUX.bgColor
        return bg
    }()
    
    var connectingForwards = true
    var connectingBackwards = true
    
    var isCurrentTab = false  {
        didSet {
            if(isCurrentTab) {
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
    
    var isPrivate = false  {
        didSet {
            label.textColor = isPrivate ? UIColor.whiteColor() : UIColor.blackColor()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clearColor()
        selectionStyle = .None
        
        contentView.addSubview(bg)
        contentView.addSubview(faviconView)
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
        super.drawRect(rect)
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
            self.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.1)
        }
        else {
            self.backgroundColor = UIColor.clearColor()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        connectingForwards = true
        connectingBackwards = true
        isCurrentTab = false
        label.font = UIFont(name:"HelveticaNeue", size: BackForwardViewCellUX.fontSize)
        
        bg.snp_updateConstraints { make in
            make.height.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
            make.width.equalTo(BackForwardViewCellUX.faviconWidth+BackForwardViewCellUX.borderSmall)
        }
    }
}