// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

final class TranslationPickerSettingsViewController: UIViewController,
                                               StoreSubscriber,
                                               Themeable,
                                               UICollectionViewDelegate {
    typealias SubscriberStateType = TranslationSettingsState

    // MARK: - Diffable types

    private typealias CellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TranslationSettingsItem>

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: TranslationSettingsDiffableDataSource = makeDataSource()

    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    var currentWindowUUID: WindowUUID? { return windowUUID }

    let windowUUID: WindowUUID
    private var state: TranslationSettingsState

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        state = TranslationSettingsState(windowUUID: windowUUID)
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
        applyTheme()
        subscribeToRedux()
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.viewDidLoad
        ))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromRedux()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.dispatch(ComponentAction(
            windowUUID: windowUUID,
            actionType: ComponentActionType.addComponent,
            component: .translationSettings
        ))
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select { appState in
                TranslationSettingsState(appState: appState, uuid: uuid)
            }
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ComponentAction(
            windowUUID: windowUUID,
            actionType: ComponentActionType.removeComponent,
            component: .translationSettings
        ))
        store.unsubscribe(self)
    }

    func newState(state: TranslationSettingsState) {
        self.state = state
        dataSource.applySnapshot(state: state, animated: true)
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

    private func makeLayout(backgroundColor: UIColor? = nil) -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.footerMode = .supplementary
        config.backgroundColor = backgroundColor
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    // MARK: - Data source

    private func makeDataSource() -> TranslationSettingsDiffableDataSource {
        let toggleReg = makeToggleCellRegistration()
        let languageReg = makeLanguageCellRegistration()
        let addLanguageReg = makeAddLanguageCellRegistration()

        let dataSource = TranslationSettingsDiffableDataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .enableToggle:
                return collectionView.dequeueConfiguredReusableCell(
                    using: toggleReg, for: indexPath, item: item)
            case .language:
                return collectionView.dequeueConfiguredReusableCell(
                    using: languageReg, for: indexPath, item: item)
            case .addLanguage:
                return collectionView.dequeueConfiguredReusableCell(
                    using: addLanguageReg, for: indexPath, item: item)
            }
        }

        let headerReg = dataSource.makeHeaderRegistration()
        let footerReg = dataSource.makeFooterRegistration()
        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
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

        return dataSource
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
            guard let self, case let .language(details) = item else { return }
            var content = cell.defaultContentConfiguration()
            let theme = self.themeManager.getCurrentTheme(for: self.windowUUID)
            content.text = details.mainText
            content.textProperties.color = theme.colors.textPrimary
            content.secondaryText = details.subtitleText
            content.secondaryTextProperties.color = theme.colors.textSecondary
            cell.accessories = []
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.backgroundConfiguration?.backgroundColor = theme.colors.layer2
        }
    }

    private func makeAddLanguageCellRegistration() -> CellRegistration {
        CellRegistration { [weak self] cell, _, _ in
            guard let self else { return }
            var content = cell.defaultContentConfiguration()
            let theme = self.themeManager.getCurrentTheme(for: self.windowUUID)
            content.text = .Settings.Translation.PreferredLanguages.AddLanguage
            content.textProperties.color = theme.colors.actionPrimary
            cell.accessories = [.disclosureIndicator()]
            cell.contentConfiguration = content
            cell.backgroundConfiguration = .listGroupedCell()
            cell.backgroundConfiguration?.backgroundColor = theme.colors.layer2
        }
    }

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
        collectionView.setCollectionViewLayout(makeLayout(backgroundColor: theme.colors.layer1), animated: false)
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        dataSource.reconfigureVisibleCells()
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return dataSource.itemIdentifier(for: indexPath) == .addLanguage
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard dataSource.itemIdentifier(for: indexPath) == .addLanguage else { return }
        let picker = TranslationLanguagePickerViewController(
            windowUUID: windowUUID,
            preferredLanguages: state.preferredLanguages.map { $0.code },
            supportedLanguages: state.supportedLanguages
        )
        let navigationController = UINavigationController(rootViewController: picker)
        present(navigationController, animated: true)
    }
}
