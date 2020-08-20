//
//  TopSitesWidget.swift
//  Client
//
//  Created by Sawyer Blatz on 8/10/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import SwiftUI
import WidgetKit
import SDWebImage
import UIKit
import Combine

struct TabProvider: TimelineProvider {
    public typealias Entry = OpenTabsEntry

    public func snapshot(with context: Context, completion: @escaping (OpenTabsEntry) -> ()) {
        
        let allOpenTabs = TabArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath())
        
        let openTabs = allOpenTabs.filter { $0.url != nil }
        
        // TODO: Filter out "bad tabs" like ones without URLs?
        let faviconFetchGroup = DispatchGroup()
        
        var tabFaviconDictionary = [URL : Image?]()
        
        for tab in openTabs {
            faviconFetchGroup.enter()

            if let faviconURL = tab.faviconURL {
                // TODO: sometimes this fails... maybe try to have a fallback after X time
                getImageForUrl(URL(string: faviconURL)!, completion: { image in
                    tabFaviconDictionary[tab.url!] = image
                    // Sometimes get a crash here for, my guess is, leaving twice?
                    faviconFetchGroup.leave()
                })
            } else {
                tabFaviconDictionary[tab.url!] = nil
                faviconFetchGroup.leave()
            }
        }
        
        faviconFetchGroup.notify(queue: .main) {
            let openTabsEntry = OpenTabsEntry(date: Date(), favicons: tabFaviconDictionary, tabs: openTabs)
            completion(openTabsEntry)
        }
    }

    public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        snapshot(with: context, completion: { openTabsEntry in
            let timeline = Timeline(entries: [openTabsEntry], policy: .atEnd)
            completion(timeline)
        })
    }
    
    // TODO: Handle fallback after a second?
    func getImageForUrl(_ url: URL, completion: @escaping (Image?) -> Void) {
        let queue = DispatchQueue.global()
        
        var fetchImageWork: DispatchWorkItem?
        fetchImageWork = DispatchWorkItem {
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(Image(uiImage: image))
                    }
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        
        queue.async(execute: fetchImageWork!)
//        queue.asyncAfter(deadline: .now() + 0.1) {
//            fetchImageWork?.cancel()
//            completion(nil)
//        }
    }
    
    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }
}

struct OpenTabsEntry: TimelineEntry {
    let date: Date
    let favicons: [URL : Image?]
    let tabs: [SavedTab]
}

struct OpenTabsWidget: Widget {
    private let kind: String = "Quick View"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            OpenTabsView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Quick View")
        .description("Access your open tabs directly on your homescreen.")
    }
}

struct OpenTabsView: View {
   
    let entry: OpenTabsEntry
    
    @State var tabImage: Image?
    
    @Environment(\.widgetFamily) var widgetFamily
    
    @ViewBuilder
    func lineItemForTab(_ tab: SavedTab) -> some View {
        let url = tab.url!
        Link(destination: linkToContainingApp("?url=\(url)", query: "open-url")) {
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 15) {
                    if (entry.favicons[url]! != nil) {
                        (entry.favicons[url])!!.resizable().frame(width: 16, height: 16)
                    } else {
                        Image("placeholderFavicon")
                            .foregroundColor(Color.white)
                            .frame(width: 16, height: 16)
                    }
                   
                    Text(tab.title!)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                }.padding(.horizontal)
                
                Rectangle()
                    .fill(Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.3)))
                    .frame(height: 0.5)
                    .padding(.leading, 45)
            }
        }
    }
    
    var openFirefoxButton: some View {
        HStack(alignment: .center, spacing: 15) {
            Image("openFirefox").foregroundColor(Color.white)
            Text("Open Firefox").foregroundColor(Color.white).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
            Spacer()
        }.padding([.horizontal])
    }
    
    var numberOfTabsToDisplay: Int {
        if widgetFamily == .systemMedium {
            return 3
        } else {
            return 6
        }
    }
    
    var body: some View {
        Group {
            if entry.tabs.isEmpty {
                VStack {
                    Text("No Open Tabs")
                    HStack {
                        Spacer()
                        Image("openFirefox")
                        Text("Open Firefox").foregroundColor(Color.white).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                }.foregroundColor(Color.white)
            } else {
                VStack(spacing: 8) {
//                    if entry.tabs.count >= numberOfTabsToDisplay {
//                        // Vertically center the content if the widget is full
//                        Spacer()
//                    }
//
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }
                    
                    if (entry.tabs.count > numberOfTabsToDisplay) {
                        // TODO: Deep link to tabs tray
                        HStack(alignment: .center, spacing: 15) {
                            Image("openFirefox").foregroundColor(Color.white).frame(width: 16, height: 16)
                            Text("+\(entry.tabs.count - numberOfTabsToDisplay) More...").foregroundColor(Color.white).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
                            Spacer()
                        }.padding([.horizontal])
                    } else {
                        openFirefoxButton
                    }
                    
                    Spacer()
                }.padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill((Color(UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.00)))))
        
    }
    
    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
   
}
