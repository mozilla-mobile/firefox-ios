/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI
import WidgetKit
import UIKit
import Combine

struct TabProvider: TimelineProvider {
    public typealias Entry = OpenTabsEntry
    
    public func snapshot(with context: Context, completion: @escaping (OpenTabsEntry) -> ()) {
        let allOpenTabs = TabArchiver.tabsToRestore(tabsStateArchivePath: tabsStateArchivePath())
        let openTabs = allOpenTabs.filter {
            !$0.isPrivate &&
            $0.sessionData != nil &&
            $0.url?.absoluteString.starts(with: "internal://") == false &&
            $0.title != nil
        }
        
        let faviconFetchGroup = DispatchGroup()
        
        var tabFaviconDictionary = [String : Image]()
        
        
        
        for tab in openTabs {
            faviconFetchGroup.enter()
            
            if let faviconURL = tab.faviconURL {
                getImageForUrl(URL(string: faviconURL)!, completion: { image in
                    if image != nil {
                        // TODO: I know this is not unique, but what else can I use?
                        tabFaviconDictionary[tab.title!] = image
                    }
                    
                    faviconFetchGroup.leave()
                })
            } else {
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
}

struct OpenTabsEntry: TimelineEntry {
    let date: Date
    let favicons: [String : Image]
    let tabs: [SavedTab]
}

struct OpenTabsWidget: Widget {
    private let kind: String = "Quick View"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            OpenTabsView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescription)
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry
        
    @Environment(\.widgetFamily) var widgetFamily
    
    @ViewBuilder
    func lineItemForTab(_ tab: SavedTab) -> some View {
        let url = tab.sessionData!.urls.last!

        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?url=\(url)", query: "open-url")) {
                HStack(alignment: .center, spacing: 15) {
                    if (entry.favicons[tab.title!] != nil) {
                        (entry.favicons[tab.title!])!.resizable().frame(width: 16, height: 16)
                    } else {
                        Image("placeholderFavicon")
                            .foregroundColor(Color.white)
                            .frame(width: 16, height: 16)
                    }
                    
                    Text(tab.title ?? ":(")
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                }.padding(.horizontal)
            }
            
            Rectangle()
                .fill(Color(UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.3)))
                .frame(height: 0.5)
                .padding(.leading, 45)
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
            return 8
        }
    }
    
    var body: some View {
        Group {
            if entry.tabs.isEmpty {
                VStack {
                    Text(String.NoOpenTabsLabel)
                    HStack {
                        Spacer()
                        Image("openFirefox")
                        Text(String.OpenFirefoxLabel).foregroundColor(Color.white).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                }.foregroundColor(Color.white)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }
                    
                    if (entry.tabs.count > numberOfTabsToDisplay) {
                        HStack(alignment: .center, spacing: 15) {
                            Image("openFirefox").foregroundColor(Color.white).frame(width: 16, height: 16)
                            Text(String.localizedStringWithFormat(String.MoreTabsLabel, (entry.tabs.count - numberOfTabsToDisplay)))
                                .foregroundColor(Color.white).lineLimit(1).font(.system(size: 13, weight: .semibold, design: .default))
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
        .background((Color(UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.00))))
    }
    
    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
    }
}
