// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

class WallpaperSettingsViewController: UIViewController {

    // MARK: - UIElements
    // Collection View
    lazy var collectionTitle: UILabel = .build { label in
        label.text = "This is a test"
    }

    lazy var collectionContainer: UIView = .build { view in
    }

    lazy var collectionView: UICollectionView = .build { collectionView in

    }

    // Switch
    lazy var switchContainer: UIView = .build { view in
    }

    lazy var switchTitle: UILabel = .build { label in
        label.text = "This is a test"
    }

    lazy var logoSwitch: UISwitch = .build { toggle in

    }

    lazy var switchLine: UIView = .build { view in
    }

    // MARK: - Variables
    var profile: Profile
    var wallpaperManager = WallpaperManager()

    // MARK: - Initializers
    init(with profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .Settings.Homepage.CustomizeFirefoxHome.Wallpaper
        setupView()
        applyTheme()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        view.addSubview(collectionTitle)
        view.addSubview(collectionContainer)

        switchContainer.addSubview(switchTitle)
        switchContainer.addSubview(logoSwitch)
        switchContainer.addSubview(switchLine)
        view.addSubview(switchContainer)

        NSLayoutConstraint.activate([
            // Collection View
            collectionTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 19),
            collectionTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionContainer.topAnchor.constraint(equalTo: collectionTitle.bottomAnchor, constant: 9),
            collectionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionContainer.heightAnchor.constraint(equalToConstant: 100),

            // Switch View
            logoSwitch.trailingAnchor.constraint(equalTo: switchContainer.trailingAnchor, constant: 16),
            logoSwitch.centerYAnchor.constraint(equalTo: switchContainer.centerYAnchor),

            switchTitle.leadingAnchor.constraint(equalTo: switchContainer.leadingAnchor, constant: 16),
            switchTitle.topAnchor.constraint(equalTo: switchContainer.topAnchor, constant: 11),
            switchTitle.trailingAnchor.constraint(equalTo: logoSwitch.leadingAnchor, constant: -16),
            switchTitle.bottomAnchor.constraint(equalTo: switchContainer.bottomAnchor, constant: -11),

            switchLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switchLine.topAnchor.constraint(equalTo: switchContainer.bottomAnchor),
            switchLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            switchLine.heightAnchor.constraint(equalToConstant: 0.5),

            switchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            switchContainer.topAnchor.constraint(equalTo: collectionContainer.bottomAnchor, constant: 8),
            switchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            switchContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleNotifications),
                                               name: .DisplayThemeChanged,
                                               object: nil)
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }

    // MARK: - Helper Methods

}

extension WallpaperSettingsViewController: NotificationThemeable {
    func applyTheme() {
        view.backgroundColor = UIColor.theme.homePanel.topSitesBackground

        collectionContainer.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        switchContainer.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        switchLine.backgroundColor = .systemPink
    }
}
