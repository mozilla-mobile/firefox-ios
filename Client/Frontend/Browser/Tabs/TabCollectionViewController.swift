// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class TabCollectionViewController: UIViewController,
                                   Themeable {
    struct UX {}

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: UI elements
    private var backgroundPrivacyOverlay: UIView = .build { _ in }
    private var collectionView: UICollectionView!

    // Redux state
    var isPrivateMode: Bool

    init(isPrivateMode: Bool,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.isPrivateMode = isPrivateMode
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        listenForThemeChange(view)
        applyTheme()
    }

    private func setupView() {
        setupCollectionView()
        view.addSubview(collectionView)
        view.addSubview(backgroundPrivacyOverlay)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backgroundPrivacyOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundPrivacyOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundPrivacyOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundPrivacyOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        backgroundPrivacyOverlay.isHidden = !isPrivateMode
        // TODO: Empty private tabs view FXIOS-6925
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(cellType: LegacyTabCell.self)

        // TODO: FXIOS-6926 Create TabDisplayManager and update delegates
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func applyTheme() {
        backgroundPrivacyOverlay.backgroundColor = themeManager.currentTheme.colors.layerScrim
        collectionView.backgroundColor = themeManager.currentTheme.colors.layer3
    }
}

// TODO: Remove once FXIOS-6926 is done
extension TabCollectionViewController: UICollectionViewDataSource,
                                       UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LegacyTabCell.cellIdentifier, for: indexPath)

        return cell
    }
}
