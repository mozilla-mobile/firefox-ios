// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

// MARK: - Section / Item enums

private enum TranslationSettingsSection: Int, Hashable {
    case enableToggle
    case preferredLanguages
}

private enum TranslationSettingsItem: Hashable {
    case enableToggle
    case language(code: String, isDeviceLanguage: Bool)
}

// MARK: - TranslationSettingsViewController

final class TranslationSettingsViewController: UIViewController,
                                               StoreSubscriber,
                                               Themeable {
    typealias SubscriberStateType = TranslationSettingsState

    // MARK: - Diffable types

    private typealias DataSource = UICollectionViewDiffableDataSource<TranslationSettingsSection, TranslationSettingsItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<TranslationSettingsSection, TranslationSettingsItem>
    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TranslationSettingsItem>
    private typealias SupplementaryRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>

    // MARK: - UI

    private lazy var collectionView: UICollectionView = .build(nil) { [self] in
        UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    }

    private lazy var dataSource: DataSource = makeDataSource()

    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    var currentWindowUUID: WindowUUID? { return windowUUID }

    // MARK: - State

    let windowUUID: WindowUUID
    private var state: TranslationSettingsState

    // MARK: - Init

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.state = TranslationSettingsState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)
        title = .Settings.Translation.Title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        subscribeToRedux()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.viewDidLoad
        ))
        store.dispatch(ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.showScreen,
            screen: .translationSettings
        ))
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select { appState in
                TranslationSettingsState(appState: appState, uuid: uuid)
            }
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ScreenAction(
            windowUUID: windowUUID,
            actionType: ScreenActionType.closeScreen,
            screen: .translationSettings
        ))
        store.unsubscribe(self)
    }

    func newState(state: TranslationSettingsState) {
        self.state = state
        applySnapshot(state: state, animated: true)
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.footerMode = .supplementary
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    // MARK: - Data source

    private func makeDataSource() -> DataSource {
        let toggleReg = makeToggleCellRegistration()
        let languageReg = makeLanguageCellRegistration()
        let headerReg = makeHeaderRegistration()
        let footerReg = makeFooterRegistration()

        let ds = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .enableToggle:
                return collectionView.dequeueConfiguredReusableCell(
                    using: toggleReg, for: indexPath, item: item)
            case .language:
                return collectionView.dequeueConfiguredReusableCell(
                    using: languageReg, for: indexPath, item: item)
            }
        }

        ds.supplementaryViewProvider = { collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerReg, for: indexPath)
            case UICollectionView.elementKindSectionFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: footerReg, for: indexPath)
            default:
                return nil
            }
        }

        return ds
    }

    private func makeToggleCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, _, item in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            let theme = self.themeManager.getCurrentTheme(for: self.windowUUID)

            switch item {
            case .enableToggle:
                content.text = .Settings.Translation.ToggleTitle
                content.textProperties.color = theme.colors.textPrimary
                let toggle = UISwitch()
                toggle.isOn = self.state.isTranslationsEnabled
                toggle.onTintColor = theme.colors.actionPrimary
                toggle.addTarget(self, action: #selector(self.didToggleTranslations(_:)), for: .valueChanged)
                cell.accessories = [.customView(configuration: .init(
                    customView: toggle,
                    placement: .trailing(displayed: .always)
                ))]
            default:
                break
            }
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.backgroundConfiguration?.backgroundColor = theme.colors.layer2
        }
    }

    private func makeLanguageCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, _, item in
            guard let self, case let .language(code, isDevice) = item else { return }
            var content = cell.defaultContentConfiguration()
            let theme = self.themeManager.getCurrentTheme(for: self.windowUUID)
            let native = Self.nativeName(for: code)
            let localized = Self.localizedName(for: code)
            content.text = native
            content.textProperties.color = theme.colors.textPrimary
            let subtitle = isDevice ? .Settings.Translation.PreferredLanguages.DeviceLanguage
                                    : (native == localized ? nil : localized)
            content.secondaryText = subtitle
            content.secondaryTextProperties.color = theme.colors.textSecondary
            cell.accessories = []
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.backgroundConfiguration?.backgroundColor = theme.colors.layer2
        }
    }

    private func makeHeaderRegistration() -> SupplementaryRegistration {
        SupplementaryRegistration(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] cell, _, indexPath in
            guard let self else { return }
            let sections = self.dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return }
            var content = UIListContentConfiguration.groupedHeader()
            content.textProperties.transform = .none
            switch sections[indexPath.section] {
            case .preferredLanguages:
                content.text = .Settings.Translation.PreferredLanguages.SectionTitle
            default:
                content.text = nil
            }
            cell.contentConfiguration = content
        }
    }

    private func makeFooterRegistration() -> SupplementaryRegistration {
        SupplementaryRegistration(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] cell, _, indexPath in
            guard let self else { return }
            let sections = self.dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return }
            var content = UIListContentConfiguration.groupedFooter()
            switch sections[indexPath.section] {
            case .enableToggle:
                content.text = .Settings.Translation.ToggleFooter
            case .preferredLanguages:
                content.text = .Settings.Translation.PreferredLanguages.Footer
            }
            cell.contentConfiguration = content
        }
    }

    // MARK: - Snapshot

    private func applySnapshot(state: TranslationSettingsState, animated: Bool) {
        var snapshot = Snapshot()
        snapshot.appendSections([.enableToggle])
        snapshot.appendItems([.enableToggle], toSection: .enableToggle)

        if state.isTranslationsEnabled {
            snapshot.appendSections([.preferredLanguages])
            let deviceCode = Locale.current.languageCode ?? ""
            let langItems: [TranslationSettingsItem] = state.preferredLanguages.map { code in
                .language(code: code, isDeviceLanguage: code == deviceCode && code == state.preferredLanguages.first)
            }
            snapshot.appendItems(langItems, toSection: .preferredLanguages)
        }

        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    /// Reconfigures existing cells without a structural snapshot diff.
    /// Called from applyTheme to update colours without replacing live UISwitch instances.
    private func reconfigureVisibleCells() {
        var snap = dataSource.snapshot()
        let allItems = snap.sectionIdentifiers.flatMap { snap.itemIdentifiers(inSection: $0) }
        guard !allItems.isEmpty else { return }
        snap.reconfigureItems(allItems)
        dataSource.apply(snap, animatingDifferences: true)
    }

    // MARK: - Toggle actions

    @objc private func didToggleTranslations(_ sender: UISwitch) {
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        ))
    }

    // MARK: - Theming

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        collectionView.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        reconfigureVisibleCells()
    }

    // MARK: - Helpers

    static func nativeName(for code: String) -> String {
        return Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
    }

    static func localizedName(for code: String) -> String {
        return Locale.current.localizedString(forLanguageCode: code) ?? code
    }
}

// MARK: - UICollectionViewDelegate

extension TranslationSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
