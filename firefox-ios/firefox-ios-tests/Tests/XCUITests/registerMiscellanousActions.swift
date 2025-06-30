// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MappaMundi

func registerMiscellanousActions(in map: MMScreenGraph<FxUserState>) {
    // URLBarOpen is dismissOnUse, which ScreenGraph interprets as "now we've done this action,
    // then go back to the one before it" but SetURL is an action than keeps us in URLBarOpen.
    // So let's put it here.
    map.addScreenAction(Action.SetURL, transitionTo: URLBarOpen)

    // LoadURL points to WebPageLoading, which allows us to add additional
    // onEntryWaitFor requirements, which we don't need when we're returning to BrowserTab without
    // loading a webpage.
    // We do end up at WebPageLoading however, so should lead quickly back to BrowserTab.
    map.addScreenAction(Action.LoadURL, transitionTo: WebPageLoading)
}
