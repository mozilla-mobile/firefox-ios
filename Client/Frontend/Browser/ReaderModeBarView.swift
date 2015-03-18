/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Snap

enum ReaderModeBarButtonType {
    case MarkAsRead, MarkAsUnread, Settings, AddToReadingList, RemoveFromReadingList
}

protocol ReaderModeBarViewDelegate {
    func readerModeBar(readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

class ReaderModeBarView: UIView {
    var delegate: ReaderModeBarViewDelegate?

    var readStatusButton: UIButton!
    var settingsButton: UIButton!
    var listStatusButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.whiteColor()

        readStatusButton = UIButton()
        addSubview(readStatusButton)
        readStatusButton.setImage(UIImage(named: "MarkAsRead"), forState: UIControlState.Normal)
        readStatusButton.addTarget(self, action: "SELtappedReadStatusButton:", forControlEvents: UIControlEvents.TouchUpInside)
        readStatusButton.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        settingsButton = UIButton()
        addSubview(settingsButton)
        settingsButton.setImage(UIImage(named: "SettingsSerif"), forState: UIControlState.Normal)
        settingsButton.addTarget(self, action: "SELtappedSettingsButton:", forControlEvents: UIControlEvents.TouchUpInside)
        settingsButton.snp_makeConstraints { (make) -> () in
            make.height.centerX.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        listStatusButton = UIButton()
        addSubview(listStatusButton)
        listStatusButton.setImage(UIImage(named: "addToReadingList"), forState: UIControlState.Normal)
        listStatusButton.addTarget(self, action: "SELtappedListStatusButton:", forControlEvents: UIControlEvents.TouchUpInside)
        listStatusButton.snp_makeConstraints { (make) -> () in
            make.right.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, 0.5)
        CGContextSetRGBStrokeColor(context, 0.1, 0.1, 0.1, 1.0)
        CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, 0, frame.height)
        CGContextAddLineToPoint(context, frame.width, frame.height)
        CGContextStrokePath(context)
    }

    func SELtappedReadStatusButton(sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: unread ? .MarkAsRead : .MarkAsUnread)
    }

    func SELtappedSettingsButton(sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: .Settings)
    }

    func SELtappedListStatusButton(sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: added ? .RemoveFromReadingList : .AddToReadingList)
    }

    var unread: Bool = true {
        didSet {
            readStatusButton.setImage(UIImage(named: unread ? "MarkAsRead" : "MarkAsUnread"), forState: UIControlState.Normal)
        }
    }

    var added: Bool = false {
        didSet {
            listStatusButton.setImage(UIImage(named: added ? "removeFromReadingList" : "addToReadingList"), forState: UIControlState.Normal)
        }
    }
}
