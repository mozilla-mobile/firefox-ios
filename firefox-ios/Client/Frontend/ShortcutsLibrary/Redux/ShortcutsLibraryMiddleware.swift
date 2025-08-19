// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class ShortcutsLibraryMiddleware {
    private let windowManager: WindowManager
    private let themeManager: ThemeManager

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.windowManager = windowManager
        self.themeManager = themeManager
    }

    @MainActor
    lazy var shortcutsLibraryProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case  ContextMenuActionType.tappedOnOpenNewTab:
            self.handleTappedOnOpenNewTabAction(action: action)
        default:
            break
        }
    }

    @MainActor
    private func handleTappedOnOpenNewTabAction(action: Action) {
        guard let tabManager = windowManager.windows[action.windowUUID]?.tabManager,
        let url = (action as? ContextMenuAction)?.url else { return }

        let tab = tabManager.addTab(URLRequest(url: url), afterTab: tabManager.selectedTab, isPrivate: false)

        let toastType = ToastType.openNewTab

        let viewModel = ButtonToastViewModel(labelText: toastType.title, buttonText: toastType.buttonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: themeManager.getCurrentTheme(for: action.windowUUID)) { buttonPressed in
            if buttonPressed {
                tabManager.selectTab(tab)
            }
        }

        let toastAction = ShortcutsLibraryAction(toast: toast,
                                                 windowUUID: action.windowUUID,
                                                 actionType: ShortcutsLibraryMiddlewareActionType.openedNewTab)
        store.dispatchLegacy(toastAction)
    }
}
