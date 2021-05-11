/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import SnapKit

class ASLibraryCell: UICollectionViewCell, Themeable {

    var mainView = UIStackView()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []

    let bookmarks = LibraryPanel(title: Strings.AppMenuBookmarksTitleString, image: UIImage.templateImageNamed("menu-Bookmark"), color: UIColor.Photon.Blue50)
    let history = LibraryPanel(title: Strings.AppMenuHistoryTitleString, image: UIImage.templateImageNamed("menu-panel-History"), color: UIColor.Photon.Teal60)
    let readingList = LibraryPanel(title: Strings.AppMenuReadingListTitleString, image: UIImage.templateImageNamed("menu-panel-ReadingList"), color: UIColor.Photon.GreenShamrock)
    let downloads = LibraryPanel(title: Strings.AppMenuDownloadsTitleString, image: UIImage.templateImageNamed("menu-panel-Downloads"), color: UIColor.Photon.Magenta60)

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .fillEqually
        mainView.spacing = 10
        addSubview(mainView)
        mainView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        [bookmarks, history, downloads, readingList].forEach { item in
            let view = LibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 :2
            view.button.backgroundColor = item.color
            view.button.setTitleColor(UIColor.theme.homePanel.topSiteDomain, for: .normal)
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            libraryButtons.append(view)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        libraryButtons.forEach { button in
            button.title.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
