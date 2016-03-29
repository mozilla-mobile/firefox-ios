/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

enum ReaderModeBarButtonType {
    case MarkAsRead, MarkAsUnread, Settings, AddToReadingList, RemoveFromReadingList

    private var localizedDescription: String {
        switch self {
        case .MarkAsRead: return NSLocalizedString("Mark as Read", comment: "Name for Mark as read button in reader mode")
        case .MarkAsUnread: return NSLocalizedString("Mark as Unread", comment: "Name for Mark as unread button in reader mode")
        case .Settings: return NSLocalizedString("Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
        case .AddToReadingList: return NSLocalizedString("Add to Reading List", comment: "Name for button adding current article to reading list in reader mode")
        case .RemoveFromReadingList: return NSLocalizedString("Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode")
        }
    }

    private var imageName: String {
        switch self {
        case .MarkAsRead: return "MarkAsRead"
        case .MarkAsUnread: return "MarkAsUnread"
        case .Settings: return "SettingsSerif"
        case .AddToReadingList: return "addToReadingList"
        case .RemoveFromReadingList: return "removeFromReadingList"
        }
    }

    private var image: UIImage? {
        let image = UIImage(named: imageName)
        image?.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate {
    func readerModeBar(readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

struct ReaderModeBarViewUX {

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIConstants.PrivateModeReaderModeBackgroundColor
        theme.buttonTintColor = UIColor.whiteColor()
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = UIColor.whiteColor()
        theme.buttonTintColor = UIColor.darkGrayColor()
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class ReaderModeBarView: UIView {
    var delegate: ReaderModeBarViewDelegate?

    var readStatusButton: UIButton!
    var settingsButton: UIButton!
    var listStatusButton: UIButton!

    dynamic var buttonTintColor: UIColor = UIColor.clearColor() {
        didSet {
            readStatusButton.tintColor = self.buttonTintColor
            settingsButton.tintColor = self.buttonTintColor
            listStatusButton.tintColor = self.buttonTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        readStatusButton = createButton(type: .MarkAsRead, action: #selector(ReaderModeBarView.SELtappedReadStatusButton(_:)))
        readStatusButton.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        settingsButton = createButton(type: .Settings, action: #selector(ReaderModeBarView.SELtappedSettingsButton(_:)))
        settingsButton.snp_makeConstraints { (make) -> () in
            make.height.centerX.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        listStatusButton = createButton(type: .AddToReadingList, action: #selector(ReaderModeBarView.SELtappedListStatusButton(_:)))
        listStatusButton.snp_makeConstraints { (make) -> () in
            make.right.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
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

    private func createButton(type type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button = UIButton()
        addSubview(button)
        button.setImage(type.image, forState: .Normal)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        return button
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
            let buttonType: ReaderModeBarButtonType = unread && added ? .MarkAsRead : .MarkAsUnread
            readStatusButton.setImage(buttonType.image, forState: UIControlState.Normal)
            readStatusButton.enabled = added
            readStatusButton.alpha = added ? 1.0 : 0.6
        }
    }
    
    var added: Bool = false {
        didSet {
            let buttonType: ReaderModeBarButtonType = added ? .RemoveFromReadingList : .AddToReadingList
            listStatusButton.setImage(buttonType.image, forState: UIControlState.Normal)
        }
    }
}

extension ReaderModeBarView: Themeable {
    func applyTheme(themeName: String) {
        guard let theme = ReaderModeBarViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        backgroundColor = theme.backgroundColor
        buttonTintColor = theme.buttonTintColor!
    }
}