// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import Shared

final class MainMenuDetailMiddleware {
    private struct Options {
        static let zoom = "zoom"
        static let reportBrokenSite = "report_broken_site"
        static let bookmarkThisPage = "bookmark_this_page"
        static let editBookmark = "edit_bookmark"
        static let addToShortcuts = "add_to_shortcuts"
        static let removeFromShortcuts = "remove_from_shortcuts"
        static let saveToReadingList = "save_to_reading_list"
        static let removeFromReadingList = "remove_from_reading_list"
        static let nightModeTurnOn = "night_mode_turn_on"
        static let nightModeTurnOff = "night_mode_turn_off"
        static let back = "back"
    }

    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var mainMenuDetailProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }
        let isHomepage = action.currentTabInfo?.isHomepage ?? false
        switch action.actionType {
        case MainMenuDetailsActionType.tapZoom:
            self.telemetry.optionTapped(with: isHomepage, and: Options.zoom)
        case MainMenuDetailsActionType.tapReportBrokenSite:
            self.telemetry.optionTapped(with: isHomepage, and: Options.reportBrokenSite)
        case MainMenuDetailsActionType.tapAddToBookmarks:
            self.telemetry.optionTapped(with: isHomepage, and: Options.bookmarkThisPage)
        case MainMenuDetailsActionType.tapEditBookmark:
            self.telemetry.optionTapped(with: isHomepage, and: Options.editBookmark)
        case MainMenuDetailsActionType.tapAddToShortcuts:
            self.telemetry.optionTapped(with: isHomepage, and: Options.addToShortcuts)
        case MainMenuDetailsActionType.tapRemoveFromShortcuts:
            self.telemetry.optionTapped(with: isHomepage, and: Options.removeFromShortcuts)
        case MainMenuDetailsActionType.tapAddToReadingList:
            self.telemetry.optionTapped(with: isHomepage, and: Options.saveToReadingList)
        case MainMenuDetailsActionType.tapRemoveFromReadingList:
            self.telemetry.optionTapped(with: isHomepage, and: Options.removeFromReadingList)
        case MainMenuDetailsActionType.tapToggleNightMode:
            guard let isActive = action.isActive else { return }
            let option = isActive ? Options.nightModeTurnOn : Options.nightModeTurnOff
            self.telemetry.optionTapped(with: isHomepage, and: option)
        case MainMenuDetailsActionType.tapBackToMainMenu:
            self.telemetry.optionTapped(with: isHomepage, and: Options.back)
        case MainMenuDetailsActionType.tapDismissView:
            self.telemetry.closeButtonTapped(isHomepage: isHomepage)
        default:
            break
        }
    }
}
