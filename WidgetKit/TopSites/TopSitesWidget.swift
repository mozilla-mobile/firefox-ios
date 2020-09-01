/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import Combine
import Shared
import Storage
import SyncTelemetry

struct TopSitesProvider: TimelineProvider {
    public typealias Entry = TopSitesEntry

    func placeholder(in context: Context) -> TopSitesEntry {
        return TopSitesEntry(date: Date(), favicons: [String: Image](), sites: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TopSitesEntry) -> Void) {
        TopSitesHandler.getTopSites(profile: BrowserProfile(localName: "profile")).uponQueue(.main) { topSites in
            
            let faviconFetchGroup = DispatchGroup()
            var tabFaviconDictionary = [String : Image]()
            
            for site in topSites {
                faviconFetchGroup.enter()

                if let faviconURL = site.icon?.url {
                    getImageForUrl(URL(string: faviconURL)!, completion: { image in
                        if image != nil {
                            tabFaviconDictionary[site.url] = image
                        }

                        faviconFetchGroup.leave()
                    })
                } else {
                    faviconFetchGroup.leave()
                }
            }
            
            faviconFetchGroup.notify(queue: .main) {
                let topSitesEntry = TopSitesEntry(date: Date(), favicons: tabFaviconDictionary, sites: topSites)
                
                completion(topSitesEntry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TopSitesEntry>) -> Void) {
        getSnapshot(in: context, completion: { topSitesEntry in
            let timeline = Timeline(entries: [topSitesEntry], policy: .atEnd)
            completion(timeline)
        })
    }
    
    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }
}

struct TopSitesEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let sites: [Site]
}

struct TopSitesWidget: Widget {
    private let kind: String = "Top Sites"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopSitesProvider()) { entry in
            TopSitesView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName(String.TopSitesGalleryTitle)
        .description(String.TopSitesGalleryDescription)
    }
}

struct TopSitesView: View {
    let entry: TopSitesEntry
    
    @ViewBuilder
    func topSitesItem(_ site: Site) -> some View {
        let url = site.url
        
        Link(destination: linkToContainingApp("?url=\(url)", query: "open-url")) {
            if (entry.favicons[url] != nil) {
                (entry.favicons[url])!.resizable().frame(width: 60, height: 60).mask(maskShape)
            } else {
                Rectangle()
                    .fill(Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.3)))
                    .frame(width: 60, height: 60)
            }
        }
    }
    
    var maskShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 5)
    }
    
    var emptySquare: some View {
        maskShape
            .fill(Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.3)))
            .frame(width: 60, height: 60)
            .background(Color.clear).frame(maxWidth: .infinity)
    }
    
    var body: some View {
        VStack {
            // TODO: Always fill with 16 squares, no matter what!
            HStack {
                if entry.sites.count > 3 {
                    ForEach(entry.sites.prefix(4), id: \.url) { tab in
                        topSitesItem(tab)
                            .background(Color.clear).frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(entry.sites[0...entry.sites.count - 1], id: \.url) { tab in
                        topSitesItem(tab).frame(maxWidth: .infinity)
                    }
                    
                    ForEach(0..<(4 - entry.sites.count), id: \.self) { _ in
                        emptySquare
                    }
                }
            }.padding(.top)
            Spacer()
            HStack {
                if entry.sites.count > 7 {
                    ForEach(entry.sites[4...7], id: \.url) { tab in
                        topSitesItem(tab).frame(maxWidth: .infinity)
                    }
                } else {
                    // Ensure there is at least a single site in the second row
                    if entry.sites.count > 4 {
                        ForEach(entry.sites[4...entry.sites.count - 1], id: \.url) { tab in
                            topSitesItem(tab).frame(maxWidth: .infinity)
                        }
                    }
                    
                    ForEach(0..<(min(4, 8 - entry.sites.count)), id: \.self) { _ in
                        emptySquare
                    }
                }
            }.padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((Color(UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.00))))
    }
    
    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}
