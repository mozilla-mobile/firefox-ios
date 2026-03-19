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
    private let localeProvider: LocaleProvider

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.localeProvider = localeProvider
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

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.footerMode = .supplementary
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    // MARK: - Data source

    private func makeDataSource() -> TranslationSettingsDiffableDataSource {
        let toggleReg = makeToggleCellRegistration()
        let languageReg = makeLanguageCellRegistration()

        let dataSource = TranslationSettingsDiffableDataSource(
            collectionView: collectionView,
            localeProvider: localeProvider
        ) { collectionView, indexPath, item in
            switch item {
            case .enableToggle:
                return collectionView.dequeueConfiguredReusableCell(
                    using: toggleReg, for: indexPath, item: item)
            case .language:
                return collectionView.dequeueConfiguredReusableCell(
                    using: languageReg, for: indexPath, item: item)
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
            guard let self, case let .language(code, isDevice) = item else { return }
            var content = cell.defaultContentConfiguration()
            let theme = self.themeManager.getCurrentTheme(for: self.windowUUID)
            let native = Self.nativeName(for: code)
            let localized = Self.localizedName(for: code, locale: self.localeProvider.current)
            content.text = native
            content.textProperties.color = theme.colors.textPrimary
            let subtitle: String?
            if isDevice {
                subtitle = .Settings.Translation.PreferredLanguages.DeviceLanguage
            } else {
                subtitle = native == localized ? nil : localized
            }
            content.secondaryText = subtitle
            content.secondaryTextProperties.color = theme.colors.textSecondary
            cell.accessories = []
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
        collectionView.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        dataSource.reconfigureVisibleCells()
    }

    // MARK: - Helpers

    static func nativeName(for code: String) -> String {
        return Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
    }

    static func localizedName(for code: String, locale: Locale = .current) -> String {
        return locale.localizedString(forLanguageCode: code) ?? code
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}
