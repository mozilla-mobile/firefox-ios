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
    case markAsRead, markAsUnread, settings, addToReadingList, removeFromReadingList

    fileprivate var localizedDescription: String {
        switch self {
        case .markAsRead: return NSLocalizedString("Mark as Read", comment: "Name for Mark as read button in reader mode")
        case .markAsUnread: return NSLocalizedString("Mark as Unread", comment: "Name for Mark as unread button in reader mode")
        case .settings: return NSLocalizedString("Display Settings", comment: "Name for display settings button in reader mode. Display in the meaning of presentation, not monitor.")
        case .addToReadingList: return NSLocalizedString("Add to Reading List", comment: "Name for button adding current article to reading list in reader mode")
        case .removeFromReadingList: return NSLocalizedString("Remove from Reading List", comment: "Name for button removing current article from reading list in reader mode")
        }
    }

    fileprivate var imageName: String {
        switch self {
        case .markAsRead: return "MarkAsRead"
        case .markAsUnread: return "MarkAsUnread"
        case .settings: return "SettingsSerif"
        case .addToReadingList: return "addToReadingList"
        case .removeFromReadingList: return "removeFromReadingList"
        }
    }

    fileprivate var image: UIImage? {
        let image = UIImage(named: imageName)
        image?.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

struct ReaderModeBarViewUX {

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.backgroundColor = UIConstants.PrivateModeAssistantToolbarBackgroundColor
        theme.buttonTintColor = UIColor.white
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.backgroundColor = UIColor.white
        theme.buttonTintColor = UIColor.darkGray
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class ReaderModeBarView: UIView {
    var delegate: ReaderModeBarViewDelegate?

    var readStatusButton: UIButton!
    var settingsButton: UIButton!
    var listStatusButton: UIButton!

    dynamic var buttonTintColor: UIColor = UIColor.clear {
        didSet {
            readStatusButton.tintColor = self.buttonTintColor
            settingsButton.tintColor = self.buttonTintColor
            listStatusButton.tintColor = self.buttonTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        readStatusButton = createButton(.markAsRead, action: #selector(ReaderModeBarView.SELtappedReadStatusButton(_:)))
        readStatusButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        settingsButton = createButton(.settings, action: #selector(ReaderModeBarView.SELtappedSettingsButton(_:)))
        settingsButton.snp.makeConstraints { (make) -> Void in
            make.height.centerX.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        listStatusButton = createButton(.addToReadingList, action: #selector(ReaderModeBarView.SELtappedListStatusButton(_:)))
        listStatusButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(0.5)
        context.setStrokeColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        context.setStrokeColor(UIColor.gray.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: frame.height))
        context.addLine(to: CGPoint(x: frame.width, y: frame.height))
        context.strokePath()
    }

    fileprivate func createButton(_ type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button = UIButton()
        addSubview(button)
        button.setImage(type.image, for: UIControlState())
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func SELtappedReadStatusButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: unread ? .markAsRead : .markAsUnread)
    }

    func SELtappedSettingsButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: .settings)
    }

    func SELtappedListStatusButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: added ? .removeFromReadingList : .addToReadingList)
    }

    var unread: Bool = true {
        didSet {
            let buttonType: ReaderModeBarButtonType = unread && added ? .markAsRead : .markAsUnread
            readStatusButton.setImage(buttonType.image, for: UIControlState())
            readStatusButton.isEnabled = added
            readStatusButton.alpha = added ? 1.0 : 0.6
        }
    }
    
    var added: Bool = false {
        didSet {
            let buttonType: ReaderModeBarButtonType = added ? .removeFromReadingList : .addToReadingList
            listStatusButton.setImage(buttonType.image, for: UIControlState())
        }
    }
}

extension ReaderModeBarView: Themeable {
    func applyTheme(_ themeName: String) {
        guard let theme = ReaderModeBarViewUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        backgroundColor = theme.backgroundColor
        buttonTintColor = theme.buttonTintColor!
    }
}
