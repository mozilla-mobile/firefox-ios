// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol DataObserver {
    var profile: Profile { get }
    var delegate: DataObserverDelegate? { get set }

    func refreshIfNeeded(forceTopSites: Bool)
}

protocol DataObserverDelegate: AnyObject {
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool)
    func willInvalidateDataSources(forceTopSites: Bool)
}

// Make these delegate methods optional by providing default implementations
extension DataObserverDelegate {
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {}
    func willInvalidateDataSources(forceTopSites: Bool) {}
}
