// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockNimbusFeatures: Features {
    public lazy var tabTrayFeature = MockTabTrayFeature()
    public lazy var homescreen = MockHomescreenFeature()
}

class MockHomescreenFeature {
    public lazy var sectionsEnabled = [HomeScreenSection.jumpBackIn: true,
                                       HomeScreenSection.pocket: true,
                                       HomeScreenSection.recentlySaved: true,
                                       HomeScreenSection.recentExplorations: true,
                                       HomeScreenSection.topSites: true,
                                       HomeScreenSection.libraryShortcuts: true]
}

class MockTabTrayFeature {
    public lazy var sectionsEnabled = [TabTraySection.inactiveTabs: true]
}
