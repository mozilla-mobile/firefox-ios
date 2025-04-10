// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

final class HomepageMiddleware {
    private let homepageTelemetry: HomepageTelemetry
    init(homepageTelemetry: HomepageTelemetry = HomepageTelemetry()) {
        self.homepageTelemetry = homepageTelemetry
    }

    lazy var homepageProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case NavigationBrowserActionType.tapOnCustomizeHomepageButton:
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: .customizeHomepage)

        case NavigationBrowserActionType.tapOnBookmarksShowMoreButton:
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: .bookmarkShowAll)

        case NavigationBrowserActionType.tapOnJumpBackInShowAllButton:
            guard case let .tabTray(panelType) = (action as? NavigationBrowserAction)?
                .navigationDestination.destination
            else { return }

            self.homepageTelemetry.sendItemTappedTelemetryEvent(
                for: panelType == .syncedTabs ? .jumpBackInSyncedTabShowAll : .jumpBackInTabShowAll
            )

        case HomepageActionType.didSelectItem:
            guard let extras = (action as? HomepageAction)?.telemetryExtras, let type = extras.itemType else {
                return
            }
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: type)

        default:
            break
        }
    }
}
