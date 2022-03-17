// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

class ASLibraryCell: UICollectionViewCell, ReusableCell {

    var mainView: UIStackView = .build()

    struct LibraryPanel {
        let title: String
        let image: UIImage?
        let color: UIColor
    }

    var libraryButtons: [LibraryShortcutView] = []
    var buttonActions: [(UIButton) -> Void] = []

    let bookmarks = LibraryPanel(title: .AppMenu.AppMenuBookmarksTitleString,
                                 image: UIImage.templateImageNamed(ImageIdentifiers.addToBookmark),
                                 color: UIColor.Photon.Blue40)
    let history = LibraryPanel(title: .AppMenu.AppMenuHistoryTitleString,
                               image: UIImage.templateImageNamed(ImageIdentifiers.history),
                               color: UIColor.Photon.Violet50)
    let readingList = LibraryPanel(title: .AppMenu.AppMenuReadingListTitleString,
                                   image: UIImage.templateImageNamed(ImageIdentifiers.readingList),
                                   color: UIColor.Photon.Pink40)
    let downloads = LibraryPanel(title: .AppMenu.AppMenuDownloadsTitleString,
                                 image: UIImage.templateImageNamed(ImageIdentifiers.downloads),
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
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mainView.removeAllArrangedViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadLayout() {
        [bookmarks, history, downloads, readingList].zip(buttonActions).forEach { (item, action) in
            let view = LibraryShortcutView()
            view.configure(item, action: action)
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            libraryButtons.append(view)
        }
    }
}
