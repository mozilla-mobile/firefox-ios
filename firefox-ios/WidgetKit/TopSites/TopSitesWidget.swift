// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import Combine

struct TopSitesWidget: Widget {
    private let kind = "Top Sites"

     var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopSitesProvider()) { entry in
            TopSitesView(entry: entry)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName(String.TopSitesGalleryTitleV2)
        .description(String.TopSitesGalleryDescription)
        .contentMarginsDisabled()
    }
}

struct TopSitesView: View {
    private struct UX {
        static let widgetBackgroundColor = Color("backgroundColor")
        static let emptySquareFillColor = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.3)
        static let itemCornerRadius: CGFloat = 5.0
        static let iconScale: CGFloat = 1.0
        static let minimumRowSpacing: CGFloat = 12.0
    }

    let entry: TopSitesEntry

    var body: some View {
        VStack {
            // Make a grid with 4 columns
            GeometryReader { provider in
                // There are 2 rows and the height of them is half of the widget height
                // So they occupy the whole available space
                let rowSize = provider.size.height / 2
                let itemSize = calculateIconSize(provider: provider, rowSize: rowSize)
                LazyVGrid(columns: (0..<4).map { _ in GridItem(.flexible(minimum: 0, maximum: .infinity)) },
                          spacing: 0,
                          content: {
                    ForEach(0..<8) { index in
                        if let site = entry.sites[safe: index] {
                            topSitesItem(site, iconSize: itemSize)
                                .frame(height: rowSize)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: rowSize)
                                .overlay {
                                    RoundedRectangle(cornerRadius: UX.itemCornerRadius)
                                        .fill(UX.emptySquareFillColor)
                                        .frame(width: itemSize, height: itemSize)
                                }
                        }
                    }
                })
            }
            .padding(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(UX.widgetBackgroundColor)
    }

    @ViewBuilder
    private func topSitesItem(_ site: WidgetTopSite, iconSize: CGFloat) -> some View {
        let url = site.url
        Link(destination: linkToContainingApp("?url=\(url)", query: "widget-medium-topsites-open-url")) {
            Group {
                if let image = entry.favicons[site.faviconImageCacheKey] {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(UX.emptySquareFillColor)
                }
            }
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: UX.itemCornerRadius))
        }
    }

    private func calculateIconSize(provider: GeometryProxy, rowSize: CGFloat) -> CGFloat {
        let dynamicIconScale = UIFontMetrics.default.scaledValue(for: UX.iconScale)
        // since the widget has 2 rows and the height of each row is half of the widget size.
        // it is set that the icon height is 4 times smaller then widget height.
        // That is the standard size for the icon and can be adjust modifyng UX.iconScale.
        // it adapts also to dynamic font scale by scaling the UX.iconScale value
        let iconHeight = (provider.size.height / 4) * dynamicIconScale
        if iconHeight > (rowSize - UX.minimumRowSpacing) {
            return rowSize - UX.minimumRowSpacing
        }
        return iconHeight
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString, invalidCharacters: false)!
    }
}
