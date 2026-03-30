// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import UIKit

// MARK: - Coordinator Delegate

@MainActor
protocol TranslationPickerSettingsDelegate: AnyObject {
    func showLanguagePicker(availableLanguages: [String])
}

// MARK: - ViewController

final class TranslationPickerSettingsViewController: UIViewController,
                                               StoreSubscriber,
                                               Themeable,
                                               UICollectionViewDelegate {
    typealias SubscriberStateType = TranslationSettingsState

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private lazy var dataSource: TranslationSettingsDiffableDataSource = makeDataSource()

    // MARK: - Navigation bar items

    private lazy var editButton = UIBarButtonItem(
        barButtonSystemItem: .edit,
        target: self,
        action: #selector(didTapEdit)
    )

    private lazy var doneButton = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: self,
        action: #selector(didTapDone)
    )

    private lazy var cancelButton = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(didTapCancel)
    )

    // MARK: - Themeable

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    var currentWindowUUID: WindowUUID? { return windowUUID }

    weak var coordinator: TranslationPickerSettingsDelegate?

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
            actionType: TranslationSettingsViewActionType.initialize
        ))
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
        let wasEditing = self.state.isEditing
        self.state = state
        if wasEditing != state.isEditing {
            collectionView.isEditing = state.isEditing
            setEditing(state.isEditing, animated: true)
        }
        updateNavBar()
        updateDoneButton()
        // Defer snapshot apply to avoid a deadlock when newState is triggered
        // from inside a UIKit snapshot apply (e.g. the swipe-to-delete handler).
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.dataSource.applySnapshot(state: self.state, animated: true)
        }
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
        let toggleReg = UICollectionView.CellRegistration<
            TranslationToggleCell, TranslationSettingsItem
        > { [weak self] cell, _, _ in
            guard let self else { return }
            cell.configure(
                isOn: state.isTranslationsEnabled,
                target: self,
                action: #selector(didToggleTranslations(_:)),
                theme: themeManager.getCurrentTheme(for: windowUUID)
            )
        }

        let languageReg = UICollectionView.CellRegistration<
            TranslationLanguageCell, TranslationSettingsItem
        > { [weak self] cell, _, item in
            guard let self, case let .language(details) = item else { return }
            cell.configure(with: details, theme: themeManager.getCurrentTheme(for: windowUUID))
            cell.accessories = [
                .delete(displayed: .whenEditing, actionHandler: { [weak self] in
                    guard let self else { return }
                    store.dispatch(TranslationSettingsViewAction(
                        languageCode: details.code,
                        windowUUID: windowUUID,
                        actionType: TranslationSettingsViewActionType.removeLanguage
                    ))
                }),
                .reorder(displayed: .whenEditing)
            ]
        }

        let addLanguageReg = UICollectionView.CellRegistration<
            TranslationAddLanguageCell, TranslationSettingsItem
        > { [weak self] cell, _, _ in
            guard let self else { return }
            cell.configure(theme: themeManager.getCurrentTheme(for: windowUUID))
        }

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

        dataSource.reorderingHandlers.canReorderItem = { [weak self] item in
            guard let self, state.isEditing else { return false }
            if case .language = item { return true }
            return false
        }

        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self else { return }
            let newItems = transaction.finalSnapshot.itemIdentifiers(inSection: .preferredLanguages)
            let reorderedLanguages = newItems.compactMap { item -> PreferredLanguageDetails? in
                if case .language(let details) = item { return details }
                return nil
            }
            store.dispatch(TranslationSettingsViewAction(
                pendingLanguages: reorderedLanguages,
                windowUUID: windowUUID,
                actionType: TranslationSettingsViewActionType.reorderLanguages
            ))
        }

        return dataSource
    }

    // MARK: - Toggle actions

    @objc private func didToggleTranslations(_ sender: UISwitch) {
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        ))
    }

    // MARK: - Nav bar

    private func updateNavBar() {
        if state.isEditing {
            navigationItem.leftBarButtonItem = cancelButton
            navigationItem.rightBarButtonItem = doneButton
        } else {
            navigationItem.leftBarButtonItem = nil
            let languages = state.preferredLanguages
            navigationItem.rightBarButtonItem = (state.isTranslationsEnabled && languages.count > 1) ? editButton : nil
        }
    }

    // MARK: - Edit mode

    @objc private func didTapEdit() {
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.enterEditMode
        ))
    }

    @objc private func didTapDone() {
        guard let pendingLanguages = state.pendingLanguages else { return }
        store.dispatch(TranslationSettingsViewAction(
            languages: pendingLanguages.map { $0.code },
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.saveLanguages
        ))
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.cancelEditMode
        ))
    }

    @objc private func didTapCancel() {
        store.dispatch(TranslationSettingsViewAction(
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.cancelEditMode
        ))
    }

    private func updateDoneButton() {
        guard state.isEditing, let pendingLanguages = state.pendingLanguages else { return }
        doneButton.isEnabled = pendingLanguages != state.preferredLanguages
    }

    // MARK: - Theming

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        collectionView.setCollectionViewLayout(makeLayout(backgroundColor: theme.colors.layer1), animated: false)
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        collectionView.visibleCells.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return dataSource.itemIdentifier(for: indexPath) == .addLanguage
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard dataSource.itemIdentifier(for: indexPath) == .addLanguage else { return }
        coordinator?.showLanguagePicker(availableLanguages: state.availableLanguages)
    }
}
