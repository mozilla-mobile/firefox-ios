// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

enum ReaderModeBarButtonType {
    case markAsRead
    case markAsUnread
    case settings
    case addToReadingList
    case removeFromReadingList

    private var localizedDescription: String {
        switch self {
        case .markAsRead: return .ReaderModeBarMarkAsRead
        case .markAsUnread: return .ReaderModeBarMarkAsUnread
        case .settings: return .ReaderModeBarSettings
        case .addToReadingList: return .ReaderModeBarAddToReadingList
        case .removeFromReadingList: return .ReaderModeBarRemoveFromReadingList
        }
    }

    private var imageName: String {
        switch self {
        case .markAsRead: return StandardImageIdentifiers.Large.notificationDotFill
        case .markAsUnread: return StandardImageIdentifiers.Large.notificationDot
        case .settings: return "SettingsSerif"
        case .addToReadingList: return StandardImageIdentifiers.Large.readingListAdd
        case .removeFromReadingList: return StandardImageIdentifiers.Large.delete
        }
    }

    var image: UIImage? {
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        image?.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate: AnyObject {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

class ReaderModeBarView: UIView, AlphaDimmable, TopBottomInterchangeable, SearchBarLocationProvider {
    private struct UX {
        static let buttonWidth: CGFloat = 80
    }

    weak var delegate: ReaderModeBarViewDelegate?

    var parent: UIStackView?

    var contextStrokeColor: UIColor?

    var readStatusButton: UIButton?
    var settingsButton: UIButton?
    var listStatusButton: UIButton?

    @objc dynamic var buttonTintColor = UIColor.clear {
        didSet {
            readStatusButton?.tintColor = self.buttonTintColor
            settingsButton?.tintColor = self.buttonTintColor
            listStatusButton?.tintColor = self.buttonTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        readStatusButton = createButton(.markAsRead, action: #selector(tappedReadStatusButton))
        readStatusButton?.accessibilityIdentifier = "ReaderModeBarView.readStatusButton"
        readStatusButton?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        readStatusButton?.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        readStatusButton?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        readStatusButton?.widthAnchor.constraint(equalToConstant: UX.buttonWidth).isActive = true

        settingsButton = createButton(.settings, action: #selector(tappedSettingsButton))
        settingsButton?.accessibilityIdentifier = "ReaderModeBarView.settingsButton"
        settingsButton?.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        settingsButton?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        settingsButton?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        settingsButton?.widthAnchor.constraint(equalToConstant: UX.buttonWidth).isActive = true

        listStatusButton = createButton(.addToReadingList, action: #selector(tappedListStatusButton))
        listStatusButton?.accessibilityIdentifier = "ReaderModeBarView.listStatusButton"
        listStatusButton?.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
        listStatusButton?.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        listStatusButton?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        listStatusButton?.widthAnchor.constraint(equalToConstant: UX.buttonWidth).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              let contextStrokeColor = contextStrokeColor else { return }

        context.setLineWidth(0.5)
        context.setStrokeColor(contextStrokeColor.cgColor)
        context.beginPath()
        let yPosition = isBottomSearchBar ? 0 : frame.height
        context.move(to: CGPoint(x: 0, y: yPosition))
        context.addLine(to: CGPoint(x: frame.width, y: yPosition))
        context.strokePath()
    }

    private func createButton(_ type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button: UIButton = .build { button in
            button.setImage(type.image, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        addSubview(button)
        return button
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.alpha = alpha
    }

    @objc
    func tappedReadStatusButton(_ sender: UIButton?) {
        delegate?.readerModeBar(self, didSelectButton: unread ? .markAsRead : .markAsUnread)
    }

    @objc
    func tappedSettingsButton(_ sender: UIButton?) {
        delegate?.readerModeBar(self, didSelectButton: .settings)
    }

    @objc
    func tappedListStatusButton(_ sender: UIButton?) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: added ? .delete : .add,
            object: .readingListItem,
            value: .readerModeToolbar
        )
        delegate?.readerModeBar(self, didSelectButton: added ? .removeFromReadingList : .addToReadingList)
    }

    var unread = true {
        didSet {
            let buttonType: ReaderModeBarButtonType = unread && added ? .markAsRead : .markAsUnread
            readStatusButton?.setImage(buttonType.image, for: .normal)
            readStatusButton?.isEnabled = added
            readStatusButton?.alpha = added ? 1.0 : 0.6
        }
    }

    var added = false {
        didSet {
            let buttonType: ReaderModeBarButtonType = added ? .removeFromReadingList : .addToReadingList
            listStatusButton?.setImage(buttonType.image, for: .normal)
        }
    }
}

extension ReaderModeBarView: ThemeApplicable {
    func applyTheme(theme: Theme) {
        let colors = theme.colors
        backgroundColor = colors.layer1
        buttonTintColor = colors.textPrimary
        contextStrokeColor = colors.textSecondary
    }
}
