// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux
import UnifiedSearchKit
import MenuKit

class SearchEngineSelectionViewController: UIViewController,
                                           UISheetPresentationControllerDelegate,
                                           UIPopoverPresentationControllerDelegate,
                                           Themeable,
                                           StoreSubscriber {
    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var currentWindowUUID: UUID? { return windowUUID }

    weak var coordinator: SearchEngineSelectionCoordinator?
    private let windowUUID: WindowUUID
    private var state: SearchEngineSelectionState
    private let logger: Logger

    // MARK: - UI/UX elements
//    // FXIOS-10192 This button is a temporary placeholder used to set up the navigation / coordinators. Will be removed.
//    private lazy var placeholderOpenSettingsButton: UIButton = .build { view in
//        view.setTitle(.UnifiedSearch.SearchEngineSelection.SearchSettings, for: .normal)
//        view.setTitleColor(.blue, for: .normal)
//        view.titleLabel?.numberOfLines = 0
//        view.titleLabel?.textAlignment = .center
//
//        view.addTarget(self, action: #selector(self.didTapOpenSettings), for: .touchUpInside)
//    }
//    // FIXME FXIOS-10189 This will be deleted later.
//    private lazy var placeholderSwitchSearchEngineButton: UIButton = .build { view in
//        view.setTitle("Test changing search engine", for: .normal)
//        view.setTitleColor(.systemPink, for: .normal)
//        view.titleLabel?.numberOfLines = 0
//        view.titleLabel?.textAlignment = .center
//
//        view.addTarget(self, action: #selector(self.testDidChangeSearchEngine), for: .touchUpInside)
//    }

    private var searchEngineTableView: SearchEngineTableView = .build()

    // MARK: - Initializers and Lifecycle

    init(
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = windowUUID
        self.state = SearchEngineSelectionState(windowUUID: windowUUID)
        self.logger = logger
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager

        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()

        // TODO Additional setup to come
        // ...
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sheetPresentationController?.delegate = self // For non-iPad setup
        popoverPresentationController?.delegate = self // For iPad setup

        setupView()
        listenForThemeChange(view)

        store.dispatch(
            SearchEngineSelectionAction(
                windowUUID: self.windowUUID,
                actionType: SearchEngineSelectionActionType.viewDidLoad
            )
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    // MARK: - UI / UX

    private func setupView() {
//        view.addSubview(placeholderOpenSettingsButton)
//        view.addSubviews(placeholderSwitchSearchEngineButton)
//
//        NSLayoutConstraint.activate([
//            placeholderOpenSettingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
//            placeholderOpenSettingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            placeholderOpenSettingsButton.widthAnchor.constraint(equalToConstant: 200),
//
//            placeholderSwitchSearchEngineButton.topAnchor.constraint(equalTo: placeholderOpenSettingsButton.bottomAnchor),
//            placeholderSwitchSearchEngineButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//        ])

        view.addSubview(searchEngineTableView)

        NSLayoutConstraint.activate([
            searchEngineTableView.topAnchor.constraint(equalTo: view.topAnchor),
            searchEngineTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            searchEngineTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchEngineTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.showScreen,
                screen: .searchEngineSelection
            )
        )

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return SearchEngineSelectionState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(
            ScreenAction(
                windowUUID: windowUUID,
                actionType: ScreenActionType.closeScreen,
                screen: .searchEngineSelection
            )
        )
    }

    func newState(state: SearchEngineSelectionState) {
        self.state = state

        // FIXME FXIOS-10189 Eventually we'll have a tableview. Placeholder for temporary testing redux.
//        placeholderSwitchSearchEngineButton.setTitle(state.searchEngines.last?.shortName ?? "Empty!", for: .normal)

        let searchEngineElements = state.searchEngines.map { engine in
            return MenuElement(
                title: engine.shortName,
                iconName: "", // TODO
                isEnabled: true,
                isActive: false,
                a11yLabel: "", // TODO
                a11yHint: nil, // TODO
                a11yId: "", // TODO
                action: nil
            )
        }

        let searchButton = MenuElement(
            title: "Search Settings", // TODO l10n
            iconName: "", // TODO
            isEnabled: true,
            isActive: false,
            a11yLabel: "", // TODO
            a11yHint: nil, // TODO
            a11yId: "",
            action: { [weak self] in
                self?.didTapOpenSettings()
            })

        let searchEngineSections: [MenuSection] = [
            MenuSection(options: searchEngineElements),
            MenuSection(options: [searchButton])
        ]

        searchEngineTableView.reloadTableView(with: searchEngineSections)
    }

    // MARK: - Theme

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        view.backgroundColor = theme.colors.layer3
        searchEngineTableView.applyTheme(theme: theme)
    }

    // MARK: - UISheetPresentationControllerDelegate inheriting UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        coordinator?.dismissModal(animated: true)
    }

    // MARK: - Navigation

    func didTapOpenSettings() {
        coordinator?.navigateToSearchSettings(animated: true)
    }

    // FIXME FXIOS-10189 This will be deleted later.
    @objc
    func testDidChangeSearchEngine(sender: UIButton) {
        // TODO FXIOS-10384 Push action to the toolbar to update the search engine selection for the next search and
        // to focus the toolbar (if it isn't already focused).
    }
}
