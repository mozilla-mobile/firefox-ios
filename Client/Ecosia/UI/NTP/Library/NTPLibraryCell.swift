/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Common

class NTPLibraryCell: UICollectionViewCell, Themeable, ReusableCell {

    var mainView = UIStackView()
    weak var widthConstraint: NSLayoutConstraint!
    weak var heightConstraint: NSLayoutConstraint!
    weak var delegate: NTPLibraryDelegate?

    enum Item: Int, CaseIterable {
        case bookmarks
        case history
        case readingList
        case downloads
        
        var title: String {
            switch self {
            case .bookmarks: return .AppMenu.AppMenuBookmarksTitleString
            case .history: return .AppMenu.AppMenuHistoryTitleString
            case .readingList: return .AppMenu.AppMenuReadingListTitleString
            case .downloads: return .AppMenu.AppMenuDownloadsTitleString
            }
        }
        var image: UIImage? {
            switch self {
            case .bookmarks: return .init(named: "libraryFavorites")
            case .history: return .init(named: "libraryHistory")
            case .readingList: return .init(named: "libraryReading")
            case .downloads: return .init(named: "libraryDownloads")
            }
        }
    }

    var shortcuts: [NTPLibraryShortcutView] = []
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .fillEqually
        mainView.spacing = 0
        mainView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        let widthConstraint = mainView.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint.priority = .defaultHigh
        widthConstraint.isActive = true
        self.widthConstraint = widthConstraint

        let heightConstraint = mainView.heightAnchor.constraint(equalToConstant: 100)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint

        // Ecosia: Show history instead of synced tabs
        Item.allCases.forEach { item in
            let view = NTPLibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.button.tag = item.rawValue
            view.button.addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 : 2
            view.accessibilityLabel = item.title
            view.isAccessibilityElement = true
            view.shouldGroupAccessibilityChildren = true
            view.accessibilityTraits = .button
            view.accessibilityRespondsToUserInteraction = true
            mainView.addArrangedSubview(view)
            shortcuts.append(view)
        }
        applyTheme()
        listenForThemeChange(contentView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        shortcuts.forEach { item in
            item.title.textColor = .legacyTheme.ecosia.primaryText
            item.button.tintColor = .legacyTheme.ecosia.primaryButton
            item.button.backgroundColor = .legacyTheme.ecosia.secondaryButton
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func tapped(_ sender: UIButton) {
        switch Item(rawValue: sender.tag) {
        case .bookmarks:
            delegate?.libraryCellOpenBookmarks()
        case .history:
            delegate?.libraryCellOpenHistory()
        case .readingList:
            delegate?.libraryCellOpenReadlist()
        case .downloads:
            delegate?.libraryCellOpenDownloads()
        default:
            break
        }
    }
}
