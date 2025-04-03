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
        case HomepageActionType.viewWillAppear, TabPanelMiddlewareActionType.didTabTrayClose:
            self.homepageTelemetry.sendHomepageImpressionEvent()
        case NavigationBrowserActionType.tapOnCustomizeHomepage:
            self.homepageTelemetry.sendTapOnCustomizeHomepageTelemetry()
        default:
            break
        }
    }
}
