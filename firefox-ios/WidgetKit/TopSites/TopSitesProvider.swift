// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import SiteImageView
import Storage
import Common
import Shared

typealias WidgetTopSite = Site

struct TopSitesProvider: TimelineProvider {
    init(userDefaults: UserDefaultsInterface = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    private let userDefaults: UserDefaultsInterface
    typealias Entry = TopSitesEntry

    func placeholder(in context: Context) -> TopSitesEntry {
        return TopSitesEntry(date: Date(), favicons: [String: Image](), sites: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TopSitesEntry) -> Void) {
        let topSites = getStoredTopSites()
        let siteImageFetcher = DefaultSiteImageHandler.factory()

        Task {
            let tabFaviconDictionary = await withTaskGroup(of: (String, UIImage).self,
                                                           returning: [String: Image].self) { group in
                for site in topSites {
                    let siteImageModel = SiteImageModel(id: UUID(),
                                                        imageType: .favicon,
                                                        siteURL: site.tileURL,
                                                        siteResource: site.faviconResource)
                    group.addTask {
                        let image = await siteImageFetcher.getImage(model: siteImageModel)
                        return (site.faviconImageCacheKey, image)
                    }
                }

                return await group.reduce(into: [:]) { $0[$1.0] = Image(uiImage: $1.1) }
            }

            let topSitesEntry = TopSitesEntry(date: Date(), favicons: tabFaviconDictionary, sites: topSites)
            completion(topSitesEntry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopSitesEntry>) -> Void) {
        getSnapshot(in: context, completion: { topSitesEntry in
            let timeline = Timeline(entries: [topSitesEntry], policy: .atEnd)
            completion(timeline)
        })
    }

    private func getStoredTopSites() -> [WidgetTopSite] {
        if let topSites = userDefaults.object(forKey: PrefsKeys.WidgetKitSimpleTopTab) as? Data {
            let decoder = JSONDecoder()
            return (try? WidgetTopSite.decode(from: decoder, data: topSites)) ?? []
        }
        return [WidgetTopSite]()
    }
}

struct TopSitesEntry: TimelineEntry {
    let date: Date
    let favicons: [String: Image]
    let sites: [WidgetTopSite]
}
