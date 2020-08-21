/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import SDWebImage
import UIKit
import Combine
//
//struct TabProvider: TimelineProvider {
//    public typealias Entry = OpenTabsEntry
//
//    public func snapshot(with context: Context, completion: @escaping (OpenTabsEntry) -> ()) {
//        let allOpenTabs = TabArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath())
//        let openTabs = allOpenTabs.filter { $0.url != nil && !$0.isPrivate }
//        let faviconFetchGroup = DispatchGroup()
//        var tabFaviconDictionary = [URL : Image]()
//
//        for tab in openTabs {
//            faviconFetchGroup.enter()
//
//            if let faviconURL = tab.faviconURL {
//                getImageForUrl(URL(string: faviconURL)!, completion: { image in
//                    if image != nil {
//                        tabFaviconDictionary[tab.url!] = image
//                    }
//
//                    faviconFetchGroup.leave()
//                })
//            } else {
//                faviconFetchGroup.leave()
//            }
//        }
//
//        faviconFetchGroup.notify(queue: .main) {
//            let openTabsEntry = OpenTabsEntry(date: Date(), favicons: tabFaviconDictionary, tabs: openTabs)
//            completion(openTabsEntry)
//        }
//    }
//
//    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        snapshot(with: context, completion: { openTabsEntry in
//            let timeline = Timeline(entries: [openTabsEntry], policy: .atEnd)
//            completion(timeline)
//        })
//    }
//
//    func getImageForUrl(_ url: URL, completion: @escaping (Image?) -> Void) {
//        let queue = DispatchQueue.global()
//
//        var fetchImageWork: DispatchWorkItem?
//
//        fetchImageWork = DispatchWorkItem {
//            if let data = try? Data(contentsOf: url) {
//                if let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        if fetchImageWork?.isCancelled == true { return }
//
//                        completion(Image(uiImage: image))
//                        fetchImageWork = nil
//                    }
//                }
//            }
//        }
//
//        queue.async(execute: fetchImageWork!)
//
//        // Timeout the favicon fetch request if it's taking too long
//        queue.asyncAfter(deadline: .now() + 2) {
//            // If we've already successfully called the completion block, early return
//            if fetchImageWork == nil { return }
//
//            fetchImageWork?.cancel()
//            completion(nil)
//        }
//    }
//
//    fileprivate func tabsStateArchivePath() -> String? {
//        let profilePath: String?
//        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
//        guard let path = profilePath else { return nil }
//        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
//    }
//}
//
//struct OpenTabsEntry: TimelineEntry {
//    let date: Date
//    let favicons: [URL : Image]
//    let tabs: [SavedTab]
//}

struct TopSitesWidget: Widget {
    private let kind: String = "Top Sites"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            TopSitesView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName(String.TopSitesGalleryTitle)
        .description(String.TopSitesGalleryDescription)
    }
}

struct TopSitesView: View {
    let entry: OpenTabsEntry
    
    @ViewBuilder
    func topSitesItem(_ tab: SavedTab) -> some View {
        let url = tab.url!
        
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
        // Using ContainerRelativeShape leads to varied sizes :(
        maskShape
            .fill(Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.3)))
            .frame(width: 60, height: 60)
            .background(Color.clear).frame(maxWidth: .infinity)

    }
    
    var body: some View {
        VStack {
            // TODO: Always fill with 16 squares, no matter what!
            HStack {
                ForEach(entry.tabs.prefix(2), id: \.self) { tab in
                    topSitesItem(tab)
                        .background(Color.clear).frame(maxWidth: .infinity)
                }
                emptySquare
                emptySquare
            }.padding(.top)
            Spacer()
            HStack {
                emptySquare
                emptySquare
                emptySquare
                emptySquare
//                ForEach(entry.tabs.suffix(4), id: \.self) { tab in
//                    topSitesItem(tab).frame(maxWidth: .infinity)
//                }
            }.padding(.bottom)
//            HStack {
//                EmptyView()
////                ForEach(entry.tabs.suffix(3), id: \.self) { tab in
////                    topSitesItem(tab)
////                }
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((Color(UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.00))))
    }
    
    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}
