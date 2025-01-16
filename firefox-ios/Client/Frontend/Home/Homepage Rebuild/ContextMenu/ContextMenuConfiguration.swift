// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
struct ContextMenuConfiguration<T: SitePr>: Equatable {
    var homepageSection: HomepageSection<T>
    var sourceView: UIView?
    var toastContainer: UIView

    var site: (any SitePr)? {
        switch item {
        case .topSite(let state, _):
            return state.site
        case .pocket(let state):
            return BasicSite(id: UUID().hashValue, url: state.url?.absoluteString ?? "", title: state.title)
        case .pocketDiscover(let state):
            return BasicSite(id: UUID().hashValue, url: state.url?.absoluteString ?? "", title: state.title)
        default:
            return nil
        }
    }

    private var item: HomepageItem<T>?

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
