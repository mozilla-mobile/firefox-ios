// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

class ASLibraryCell: UICollectionViewCell, ReusableCell, NotificationThemeable {

    var mainView: UIStackView = .build()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []

    let bookmarks = LibraryPanel(title: .AppMenuBookmarksTitleString,
                                 image: UIImage.templateImageNamed("menu-Bookmark"),
                                 color: UIColor.Photon.Blue40)
    let history = LibraryPanel(title: .AppMenuHistoryTitleString,
                               image: UIImage.templateImageNamed("menu-panel-History"),
                               color: UIColor.Photon.Violet50)
    let readingList = LibraryPanel(title: .AppMenuReadingListTitleString,
                                   image: UIImage.templateImageNamed("menu-panel-ReadingList"),
                                   color: UIColor.Photon.Pink40)
    let downloads = LibraryPanel(title: .AppMenuDownloadsTitleString,
                                 image: UIImage.templateImageNamed("menu-panel-Downloads"),
                                 color: UIColor.Photon.Green60)

    override init(frame: CGRect) {
        super.init(frame: frame)
        mainView.distribution = .equalCentering
        addSubview(mainView)

        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: topAnchor),
            mainView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mainView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        [bookmarks, history, downloads, readingList].forEach { item in
            let view = LibraryShortcutView()
            view.button.setImage(item.image, for: .normal)
            view.titleLabel.text = item.title
            let words = view.titleLabel.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.titleLabel.numberOfLines = words == 1 ? 1 : 2
            view.button.tintColor = item.color
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
            button.button.backgroundColor = UIColor.theme.homePanel.shortcutBackground
            button.button.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
            button.button.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
            button.titleLabel.textColor = UIColor.theme.homePanel.activityStreamCellTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
