/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

class NTPLibraryCell: UICollectionViewCell, NotificationThemeable, ReusableCell {

    var mainView = UIStackView()
    weak var widthConstraint: NSLayoutConstraint!
    weak var heightConstraint: NSLayoutConstraint!
    weak var delegate: NTPLibraryDelegate?

    struct Panel {
        let title: String
        let image: UIImage?
        let tag: Int
    }

    var shortcuts: [NTPLibraryShortcutView] = []

    let bookmarks = Panel(title: .AppMenu.AppMenuBookmarksTitleString, image: UIImage(named: "libraryFavorites"), tag: 0)
    let history = Panel(title: .AppMenu.AppMenuHistoryTitleString, image: UIImage(named: "libraryHistory"), tag: 1)
    let readingList = Panel(title: .AppMenu.AppMenuReadingListTitleString, image: UIImage(named: "libraryReading"), tag: 2)
    let downloads = Panel(title: .AppMenu.AppMenuDownloadsTitleString, image: UIImage(named: "libraryDownloads"), tag: 3)

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
        [bookmarks, history, readingList, downloads].forEach { item in
            let view = NTPLibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.button.tag = item.tag
            view.button.addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 : 2
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            shortcuts.append(view)
        }
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        shortcuts.forEach { item in
            item.title.textColor = .theme.ecosia.primaryText
            item.button.tintColor = .theme.ecosia.primaryButton
            item.button.backgroundColor = .theme.ecosia.secondaryButton
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func tapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            delegate?.libraryCellOpenBookmarks()
        case 1:
            delegate?.libraryCellOpenHistory()
        case 2:
            delegate?.libraryCellOpenReadlist()
        case 3:
            delegate?.libraryCellOpenDownloads()
        default:
            break
        }
    }
}
