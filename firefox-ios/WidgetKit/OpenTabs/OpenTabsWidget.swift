// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import UIKit
import Combine
import Common

struct OpenTabsWidget: Widget {
    private let kind = "Quick View"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TabProvider()) { entry in
            OpenTabsView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescriptionV2)
        .contentMarginsDisabled()
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry

    @Environment(\.widgetFamily)
    var widgetFamily

    @ViewBuilder
    func lineItemForTab(_ tab: SimpleTab) -> some View {
        let query = widgetFamily == .systemMedium ? "widget-tabs-medium-open-url" : "widget-tabs-large-open-url"
        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?uuid=\(tab.uuid)", query: query)) {
                HStack(alignment: .center, spacing: 15) {
                    if let favIcon = entry.favicons[tab.imageKey] {
                        favIcon.resizable().frame(width: 16, height: 16)
                            .foregroundColor(Color("openTabsContentColor"))
                    } else {
                        Image(decorative: StandardImageIdentifiers.Large.globe)
                            .foregroundColor(Color("openTabsContentColor"))
                            .frame(width: 16, height: 16)
                    }

                    Text(tab.title ?? "")
                        .foregroundColor(Color("openTabsContentColor"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                    Spacer()
                }.padding(.horizontal)
            }

            // Separator
            Rectangle()
                .fill(Color("separatorColor"))
                .frame(height: 0.5)
                .padding(.leading, 45)
        }
    }

    var openFirefoxButton: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(decorative: StandardImageIdentifiers.Small.externalLink)
                .foregroundColor(Color("openTabsContentColor"))
            Text("Open Firefox")
                .foregroundColor(Color("openTabsContentColor"))
                .lineLimit(1)
                .font(.system(size: 13, weight: .semibold, design: .default))
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
                        Image(decorative: StandardImageIdentifiers.Small.externalLink)
                            .foregroundColor(Color("openTabsContentColor"))
                        Text(String.OpenFirefoxLabel)
                            .foregroundColor(Color("openTabsContentColor"))
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                }
                .foregroundColor(Color("backgroundColor"))
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }

                    if entry.tabs.count > numberOfTabsToDisplay {
                        HStack(alignment: .center, spacing: 15) {
                            Image(decorative: StandardImageIdentifiers.Small.externalLink)
                                .foregroundColor(Color("openTabsContentColor"))
                                .frame(width: 16, height: 16)
                            Text(
                                String.localizedStringWithFormat(
                                    String.MoreTabsLabel,
                                    (entry.tabs.count - numberOfTabsToDisplay)
                                )
                            )
                            .foregroundColor(Color("openTabsContentColor"))
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .semibold, design: .default))
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
        .widgetBackground(Color("backgroundColor"))
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString, invalidCharacters: false)!
    }
}

struct OpenTabsPreview: PreviewProvider {
    static let favIcons = ["globe":
                            Image(decorative: StandardImageIdentifiers.Large.globe)]
    static let tabs = [SimpleTab(lastUsedTime: nil)]
    static let testEntry = OpenTabsEntry(date: Date(),
                                         favicons: favIcons,
                                         tabs: [SimpleTab]())
    static var previews: some View {
        Group {
            OpenTabsView(entry: testEntry)
        }
    }
}
