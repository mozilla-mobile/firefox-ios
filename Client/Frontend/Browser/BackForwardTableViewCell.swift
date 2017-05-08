/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class BackForwardTableViewCell: UITableViewCell {
    
    struct BackForwardViewCellUX {
        static let bgColor = UIColor(colorLiteralRed: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        static let faviconWidth = 29
        static let faviconPadding: CGFloat = 20
        static let labelPadding = 20
        static let borderSmall = 2
        static let borderBold = 5
        static let IconSize = 23
        static let fontSize: CGFloat = 12.0
    }
    
    lazy var faviconView: UIImageView = {
        let faviconView = UIImageView(image: FaviconFetcher.defaultFavicon)
        faviconView.backgroundColor = UIColor.white
        faviconView.layer.cornerRadius = 6
        faviconView.layer.borderWidth = 0.5
        faviconView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        faviconView.layer.masksToBounds = true
        return faviconView
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.text = " "
        label.font = label.font.withSize(BackForwardViewCellUX.fontSize)
        return label
    }()

    var connectingForwards = true
    var connectingBackwards = true
    
    var isCurrentTab = false {
        didSet {
            if isCurrentTab {
                label.font = UIFont(name:"HelveticaNeue-Bold", size: BackForwardViewCellUX.fontSize)
            }
        }
    }
    
    var site: Site? {
        didSet {
            if let s = site {
                faviconView.setFavicon(forSite: s, onCompletion: { [weak self] (color, url) in
                    if s.tileURL.isLocal {
                        self?.faviconView.image = UIImage(named: "faviconFox" )
                        self?.faviconView.backgroundColor = UIColor.white
                        return
                    }
                    
                    self?.faviconView.image = self?.faviconView.image?.createScaled(CGSize(width: BackForwardViewCellUX.IconSize, height: BackForwardViewCellUX.IconSize))
                    self?.faviconView.contentMode = .center
                })
                var title = s.title
                if title.isEmpty {
                    title = s.url
                }
                label.text = title
                setNeedsLayout()
            }
        }
    }
    
    var isPrivate = false {
        didSet {
            label.textColor = isPrivate ? UIColor.white : UIColor.black
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        selectionStyle = .none
        
        contentView.addSubview(faviconView)
        contentView.addSubview(label)
        
        faviconView.snp.makeConstraints { make in
            make.height.equalTo(BackForwardViewCellUX.faviconWidth)
            make.width.equalTo(BackForwardViewCellUX.faviconWidth)
            make.centerY.equalTo(self)
            make.leading.equalTo(self.snp.leading).offset(BackForwardViewCellUX.faviconPadding)
        }
        
        label.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(faviconView.snp.trailing).offset(BackForwardViewCellUX.labelPadding)
            make.trailing.equalTo(self.snp.trailing).offset(-BackForwardViewCellUX.labelPadding)
        }

    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        var startPoint = CGPoint(x: rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5),
                                     y: rect.origin.y + (connectingForwards ?  0 : rect.size.height/2))
        var endPoint   = CGPoint(x: rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5),
                                     y: rect.origin.y + rect.size.height - (connectingBackwards  ? 0 : rect.size.height/2))
        
        // flip the x component if RTL
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            startPoint.x = rect.origin.x - startPoint.x + rect.size.width
            endPoint.x = rect.origin.x - endPoint.x + rect.size.width
        }
        
        context.saveGState()
        context.setLineCap(CGLineCap.square)
        context.setStrokeColor(BackForwardViewCellUX.bgColor.cgColor)
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: startPoint.x, y: startPoint.y))
        context.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y))
        context.strokePath()
        context.restoreGState()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.1)
        } else {
            self.backgroundColor = UIColor.clear
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        connectingForwards = true
        connectingBackwards = true
        isCurrentTab = false
        label.font = UIFont(name:"HelveticaNeue", size: BackForwardViewCellUX.fontSize)
    }
}
