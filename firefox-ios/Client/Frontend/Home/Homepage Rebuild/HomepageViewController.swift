// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class HomepageViewController: UIViewController, ContentContainable, Themeable {
    // MARK: - Typealiases
    private typealias a11y = AccessibilityIdentifiers.FirefoxHomepage

    // MARK: - ContentContainable variables
    var contentType: ContentType = .newHomepage

    // MARK: - Themable variables
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Private variables
    private var collectionView: UICollectionView?
    private var dataSource: HomepageDiffableDataSource?
    private var layoutConfiguration = HomepageSectionLayoutProvider().createCompositionalLayout()
    private var logger: Logger

    // MARK: - Initializers
    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configureCollectionView()
        configureDataSource()

        dataSource?.applyInitialSnapshot()

        listenForThemeChange(view)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    // MARK: - Layout
    private func setupLayout() {
        guard let collectionView else {
            logger.log(
                "NewHomepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .legacyHomepage
            )
            return
        }

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layoutConfiguration)

        // TODO: FXIOS-10163 - Update with proper cells
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")

        collectionView.keyboardDismissMode = .onDrag
        collectionView.showsVerticalScrollIndicator = false
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.accessibilityIdentifier = a11y.collectionView

        self.collectionView = collectionView

        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        guard let collectionView else {
            logger.log(
                "NewHomepage collectionview should not have been nil, something went wrong",
                level: .fatal,
                category: .newHomepage
            )
            return
        }

        dataSource = HomepageDiffableDataSource(
            collectionView: collectionView
        ) { [weak self] (collectionView, indexPath, item) -> UICollectionViewCell? in
            return self?.configureCell(for: item, at: indexPath)
        }
    }

    private func configureCell(
        for item: HomepageDiffableDataSource.HomeItem,
        at indexPath: IndexPath
    ) -> UICollectionViewCell {
        // TODO: FXIOS-10163 - Dummy collection cells, to update with proper cells
        guard let cell: UICollectionViewCell = collectionView?.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }

        cell.contentView.backgroundColor = .systemBlue

        let label = UILabel(frame: cell.contentView.bounds)
        label.textAlignment = .center
        label.text = item.title
        label.textColor = .white
        cell.contentView.addSubview(label)
        return cell
    }
}
