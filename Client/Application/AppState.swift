/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum AppState {
    case Browser(currentURL: NSURL, isBookmarked: Bool, isDesktopSite: Bool, hasAccount: Bool, isPrivate: Bool)
    case HomePanels(selectedPanelIndex: Int, isPrivate: Bool)
    case TabsTray(isPrivate: Bool)
    case Loading

    static func getAppStateForViewController(viewController: UIViewController) -> AppState {
        if viewController.isKindOfClass(BrowserViewController) {
            return getBrowserState()
        } else if viewController.isKindOfClass(HomePanelViewController) {
            return getHomePanelsState()
        } else if viewController.isKindOfClass(TabTrayController) {
            return getTabsTrayState()
        }

        return getLoadingState()
    }

    private static func getBrowserState() -> AppState {
        guard let url = url else {
            return getHomePanelsState()
        }
        return .Browser(currentURL: url, isBookmarked: bookmarked, isDesktopSite: isDesktop, hasAccount: hasAccount, isPrivate: isPrivate)
    }

    private static func getHomePanelsState() -> AppState {
        return .HomePanels(selectedPanelIndex: homePanelState ?? 0, isPrivate: isPrivate)
    }

    private static func getTabsTrayState() -> AppState {
        return .TabsTray(isPrivate: isPrivate)
    }

    private static func getLoadingState() -> AppState {
        return .Loading
    }

    static var url: NSURL?
    static var bookmarked: Bool = false
    static var isDesktop: Bool = false
    static var hasAccount: Bool = false
    static var isPrivate: Bool = false
    static var homePanelState: Int?
}
