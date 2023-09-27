// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit

protocol TopSitesWidget {
    /// Write top sites to widgetkit
    @available(iOS 14.0, *)
    func writeWidgetKitTopSites()
}

class TopSitesWidgetManager: TopSitesWidget {
    private let topSitesProvider: TopSitesProvider

    init(topSitesProvider: TopSitesProvider) {
        self.topSitesProvider = topSitesProvider
    }

    @available(iOS 14.0, *)
    func writeWidgetKitTopSites() {
        topSitesProvider.getTopSites { sites in
            guard let sites = sites else { return }

            var widgetkitTopSites = [WidgetKitTopSiteModel]()
            sites.forEach { site in
                let imageKey = site.tileURL.baseDomain ?? ""
                if let webUrl = URL(string: site.url, encodingInvalidCharacters: false) {
                    widgetkitTopSites.append(WidgetKitTopSiteModel(title: site.title,
                                                                   url: webUrl,
                                                                   imageKey: imageKey))
                }
            }
            // save top sites for widgetkit use
            WidgetKitTopSiteModel.save(widgetKitTopSites: widgetkitTopSites)
            // Update widget timeline
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
