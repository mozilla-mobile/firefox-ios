// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import UIKit
import Combine
import Common

struct OpenTabsWidget: Widget {
    private let kind: String = "Quick View"

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
                    if entry.favicons[tab.imageKey] != nil {
                        (entry.favicons[tab.imageKey])!.resizable().frame(width: 16, height: 16)
                    } else {
                        Image(decorative: StandardImageIdentifiers.Large.globe)
                            .foregroundColor(Color.white)
                            .frame(width: 16, height: 16)
                    }

                    Text(tab.title!)
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
            Image(decorative: StandardImageIdentifiers.Small.externalLink).foregroundColor(Color.white)
            Text("Open Firefox")
                .foregroundColor(Color.white).lineLimit(1)
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
                        Text(String.OpenFirefoxLabel)
                            .foregroundColor(Color.white).lineLimit(1)
                            .font(.system(size: 13, weight: .semibold, design: .default))
                        Spacer()
                    }.padding(10)
                }.foregroundColor(Color.white)
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                        lineItemForTab(tab)
                    }

                    if entry.tabs.count > numberOfTabsToDisplay {
                        HStack(alignment: .center, spacing: 15) {
                            Image(decorative: StandardImageIdentifiers.Small.externalLink)
                                .foregroundColor(Color.white)
                                .frame(width: 16, height: 16)
                            Text(
                                String.localizedStringWithFormat(
                                    String.MoreTabsLabel,
                                    (entry.tabs.count - numberOfTabsToDisplay)
                                )
                            )
                            .foregroundColor(Color.white)
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
        .widgetBackground(Color(UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.00)))
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString, invalidCharacters: false)!
    }
}
