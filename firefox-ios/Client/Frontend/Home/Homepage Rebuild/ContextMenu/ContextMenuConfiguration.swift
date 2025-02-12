// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

struct ContextMenuConfiguration: Equatable {
    var homepageSection: HomepageSection
    var sourceView: UIView?
    var toastContainer: UIView

    var site: Site? {
        switch item {
        case .topSite(let state, _):
            return state.site
        case .jumpBackIn(let config):
            return Site.createBasicSite(url: config.siteURL, title: config.titleText)
        case .jumpBackInSyncedTab(let config):
            return Site.createBasicSite(url: config.url.absoluteString, title: config.titleText)
        case .bookmark(let state):
            return Site.createBasicSite(url: state.site.url, title: state.site.title)
        case .pocket(let state):
            return Site.createBasicSite(url: state.url?.absoluteString ?? "", title: state.title)
        case .pocketDiscover(let state):
            return Site.createBasicSite(url: state.url?.absoluteString ?? "", title: state.title)
        default:
            return nil
        }
    }

    private var item: HomepageItem?

    init(
        homepageSection: HomepageSection,
        item: HomepageItem? = nil,
        sourceView: UIView? = nil,
        toastContainer: UIView
    ) {
        self.homepageSection = homepageSection
        self.item = item
        self.sourceView = sourceView
        self.toastContainer = toastContainer
    }
}
