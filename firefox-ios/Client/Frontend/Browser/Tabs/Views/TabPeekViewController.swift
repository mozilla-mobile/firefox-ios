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

    private var tab: TabModel

    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        return makeMenuActions()
    }

    // MARK: - Lifecycle methods

    init(tab: TabModel) {
        tabPeekState = TabPeekState()
        self.tab = tab
        super.init(nibName: nil, bundle: nil)

        subscribeToRedux()
        store.dispatch(TabPeekAction.didLoadTabPeek(tabID: tab.tabUUID))
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
        store.dispatch(ActiveScreensStateAction.showScreen(.tabPeek))
        store.subscribe(self, transform: {
            return $0.select(TabPeekState.init)
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ActiveScreensStateAction.closeScreen(.tabPeek))
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
                store.dispatch(TabPeekAction.addToBookmarks(tabID: self.tab.tabUUID))
                return
            })
        }
        if tabPeekState.showSendToDevice {
            actions.append(UIAction(title: .AppMenu.TouchActions.SendToDeviceTitle,
                                    image: UIImage.templateImageNamed("menu-Send"),
                                    identifier: nil) { _ in
                store.dispatch(TabPeekAction.sendToDevice(tabID: self.tab.tabUUID))
                return
            })
        }
        if tabPeekState.showCopyURL {
            actions.append(UIAction(title: .TabPeekCopyUrl,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
                                    identifier: nil) { _ in
                store.dispatch(TabPeekAction.copyURL(tabID: self.tab.tabUUID))
                return
            })
        }
        if tabPeekState.showCloseTab {
            actions.append(UIAction(title: .TabPeekCloseTab,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                                    identifier: nil) { _ in
                store.dispatch(TabPeekAction.closeTab(tabID: self.tab.tabUUID))
                return
            })
        }

        return UIMenu(title: "", children: actions)
    }
}
