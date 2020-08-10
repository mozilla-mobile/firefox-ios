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
    
    // TODO: Implement placeholder!
    
    public func snapshot(with context: Context, completion: @escaping (OpenTabsEntry) -> ()) {
        
        let allOpenTabs = TabArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath())
        
        let openTabs = allOpenTabs.filter { $0.url != nil }
        
        // TODO: Filter out "bad tabs" like ones without URLs?
        let faviconFetchGroup = DispatchGroup()
        
        var tabFaviconDictionary = [URL : Image?]()
        
        for tab in openTabs {
            faviconFetchGroup.enter()

            if let faviconURL = tab.faviconURL {
                getImageForUrl(faviconURL, completion: { image in
                    tabFaviconDictionary[tab.url!] = image
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
    
    fileprivate func tabsStateArchivePath() -> String? {
        let profilePath: String?
        profilePath = FileManager.default.containerURL( forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
    }
    
    func getImageForUrl(_ url: String, completion: @escaping (Image) -> Void) {
        let img = UIImageView()
        
        img.sd_setImage(with: URL(string: url), completed: { _,_,_,_ in
            completion(Image(uiImage: img.image!))
        })
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
                    if (entry.favicons[url] != nil) {
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
                Divider()
                    .background(
                        Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.30))
                        .padding(.leading, 45))
            }
        }
    }
    
    var openFirefoxButton: some View {
        HStack(alignment: .center, spacing: 15) {
            Image("openFirefox").foregroundColor(Color.white)
            Text("Open Firefox").foregroundColor(Color.white).lineLimit(1).font(.system(size: 14, weight: .semibold, design: .default))
            Spacer()
        }.padding([.horizontal, .bottom])
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
                        Text("Open Firefox").foregroundColor(Color.white).lineLimit(1).font(.system(size: 14, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                    // TODO: Confirm this padding amount

                }.foregroundColor(Color.white)
            } else {
                VStack() {
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }
                    
                    // TODO: Get rid of thin little line between lineItemForTabs
                    
//                    Spacer()
                    
                    if (entry.tabs.count > numberOfTabsToDisplay) {
                        // TODO: Deep link to tabs tray
                        HStack(alignment: .center, spacing: 15) {
                            Image("openFirefox").foregroundColor(Color.white).frame(width: 16, height: 16)
                            Text("+\(entry.tabs.count - numberOfTabsToDisplay) More...").foregroundColor(Color.white).lineLimit(1).font(.system(size: 14, weight: .semibold, design: .default))
                            Spacer()
                        }.padding([.horizontal, .bottom])
                    } else {
                        openFirefoxButton
                    }
                    
                    
                    Spacer()
                }.padding(.top)
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
