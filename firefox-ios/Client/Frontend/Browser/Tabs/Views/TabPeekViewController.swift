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

    private var tab: TabModel

    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        return makeMenuActions()
    }

    // MARK: - Lifecycle methods

    init(tab: TabModel, windowUUID: WindowUUID) {
        tabPeekState = TabPeekState(windowUUID: windowUUID)
        self.tab = tab
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
        let context = TabUUIDContext(tabUUID: tab.tabUUID, windowUUID: windowUUID)
        store.dispatch(TabPeekAction.didLoadTabPeek(context))
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
        store.dispatch(ActiveScreensStateAction.showScreen(
            ScreenActionContext(screen: .tabPeek, windowUUID: windowUUID)
        ))
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return TabPeekState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ActiveScreensStateAction.closeScreen(
            ScreenActionContext(screen: .tabPeek, windowUUID: windowUUID)
        ))
        store.unsubscribe(self)
    }

    private func setupWithScreenshot() {
        let imageView: UIImageView = .build { imageView in
            imageView.image = self.tabPeekState.screenshot
        }
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
                                    identifier: nil) { _ in
                let context = TabUUIDContext(tabUUID: self.tab.tabUUID,
                                             windowUUID: self.windowUUID)
                store.dispatch(TabPeekAction.addToBookmarks(context))
                return
            })
        }
        if tabPeekState.showSendToDevice {
            actions.append(UIAction(
                title: .AppMenu.TouchActions.SendToDeviceTitle,
                image: UIImage.templateImageNamed("menu-Send"),
                identifier: nil) { _ in
                    let context = TabUUIDContext(tabUUID: self.tab.tabUUID,
                                                 windowUUID: self.windowUUID)
                    store.dispatch(TabPeekAction.sendToDevice(context))
                    return
            })
        }
        if tabPeekState.showCopyURL {
            actions.append(UIAction(title: .TabPeekCopyUrl,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
                                    identifier: nil) { _ in
                let context = TabUUIDContext(tabUUID: self.tab.tabUUID,
                                             windowUUID: self.windowUUID)
                store.dispatch(TabPeekAction.copyURL(context))
                return
            })
        }
        if tabPeekState.showCloseTab {
            actions.append(UIAction(title: .TabPeekCloseTab,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                                    identifier: nil) { _ in
                let context = TabUUIDContext(tabUUID: self.tab.tabUUID,
                                             windowUUID: self.windowUUID)
                store.dispatch(TabPeekAction.closeTab(context))
                return
            })
        }

        return UIMenu(title: "", children: actions)
    }
}
