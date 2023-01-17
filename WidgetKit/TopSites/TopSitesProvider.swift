// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import SwiftUI
import WidgetKit
import Shared
import SiteImageView

struct TopSitesProvider: TimelineProvider {
    public typealias Entry = TopSitesEntry

    func placeholder(in context: Context) -> TopSitesEntry {
        return TopSitesEntry(date: Date(), favicons: [String: Image](), sites: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TopSitesEntry) -> Void) {
        let widgetKitTopSites = WidgetKitTopSiteModel.get()
        let siteImageFetcher = DefaultSiteImageHandler.factory()

        Task {
            let tabFaviconDictionary = await withTaskGroup(of: (String, SiteImageModel).self,
                                                           returning: [String: Image].self) { group in
                for site in widgetKitTopSites {
                    group.addTask {
                        await (site.imageKey,
                               siteImageFetcher.getImage(urlStringRequest: site.url.absoluteString,
                                                         type: .favicon,
                                                         id: UUID(),
                                                         usesIndirectDomain: false))
                    }
                }

                return await group.reduce(into: [:]) { $0[$1.0] = Image(uiImage: $1.1.faviconImage ?? UIImage()) }
            }

            let topSitesEntry = TopSitesEntry(date: Date(), favicons: tabFaviconDictionary, sites: widgetKitTopSites)
            completion(topSitesEntry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopSitesEntry>) -> Void) {
        getSnapshot(in: context, completion: { topSitesEntry in
            let timeline = Timeline(entries: [topSitesEntry], policy: .atEnd)
            completion(timeline)
        })
    }
}

struct TopSitesEntry: TimelineEntry {
    let date: Date
    let favicons: [String: Image]
    let sites: [WidgetKitTopSiteModel]
}
