// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import WebKit
import Redux

class TabPeekViewController: UIViewController,
                             StoreSubscriber {
    typealias SubscriberStateType = TabPeekState

    var tabPeekState: TabPeekState
    var contextActions: UIContextMenuActionProvider = { _ in return nil }
    private let windowUUID: WindowUUID

    private var tabModel: TabModel

    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        return makeMenuActions()
    }

    // MARK: - Lifecycle methods

    init(tab: TabModel, windowUUID: WindowUUID) {
        tabPeekState = TabPeekState(windowUUID: windowUUID)
        self.tabModel = tab
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
        let action = TabPeekAction(tabUUID: tab.tabUUID,
                                   windowUUID: windowUUID,
                                   actionType: TabPeekActionType.didLoadTabPeek)
        store.dispatch(action)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contextActions = contextActions(defaultActions:)
    }

    func newState(state: TabPeekState) {
        tabPeekState = state
        setupWithScreenshot()
    }

    // MARK: - Private helper methods

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .tabPeek)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return TabPeekState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .tabPeek)
        store.dispatch(action)
    }

    private func setupWithScreenshot() {
        let imageView: UIImageView = .build { imageView in
            imageView.image = self.tabPeekState.screenshot
        }
        imageView.contentMode = .scaleAspectFill
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        imageView.accessibilityLabel = tabPeekState.previewAccessibilityLabel
    }

    private func makeMenuActions() -> UIMenu {
        var actions = [UIAction]()

        if tabPeekState.showAddToBookmarks {
            actions.append(UIAction(title: .TabPeekAddToBookmarks,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                                    identifier: nil) { [weak self] _ in
                guard let self else { return }
                let action = TabPeekAction(tabUUID: self.tabModel.tabUUID,
                                           windowUUID: self.windowUUID,
                                           actionType: TabPeekActionType.addToBookmarks)
                store.dispatch(action)
                return
            })
        }
        if tabPeekState.showCopyURL {
            actions.append(UIAction(title: .TabPeekCopyUrl,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
                                    identifier: nil) { [weak self] _ in
                guard let self else { return }
                let action = TabPeekAction(tabUUID: self.tabModel.tabUUID,
                                           windowUUID: self.windowUUID,
                                           actionType: TabPeekActionType.copyURL)
                store.dispatch(action)
                return
            })
        }
        if tabPeekState.showCloseTab {
            actions.append(UIAction(title: .TabPeekCloseTab,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                                    identifier: nil) { [weak self] _ in
                guard let self else { return }
                let action = TabPeekAction(tabUUID: self.tabModel.tabUUID,
                                           windowUUID: self.windowUUID,
                                           actionType: TabPeekActionType.closeTab)
                store.dispatch(action)
                return
            })
        }

        return UIMenu(title: "", children: actions)
    }
}
