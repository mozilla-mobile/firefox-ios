// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit
import Combine

struct TopSitesWidget: Widget {
    private let kind: String = "Top Sites"

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
        static let widgetBackgroundColor = Color(red: 0.11, green: 0.11, blue: 0.13)
        static let emptySquareFillColor = Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.3)
        static let maskShapeCornerRadius: CGFloat = 5.0
    }

    let entry: TopSitesEntry

    @ViewBuilder
    func topSitesItem(_ site: WidgetKitTopSiteModel, itemSize: CGFloat) -> some View {
        let url = site.url

        Link(destination: linkToContainingApp("?url=\(url)", query: "widget-medium-topsites-open-url")) {
            let imageSize = itemSize / 2
            if let image = entry.favicons[site.imageKey] {
                Rectangle()
                    .fill(Color.clear)
                    .overlay {
                        image
                            .resizable()
                            .frame(width: imageSize, height: imageSize)
                            .scaledToFit()
                            .mask(maskShape)
                    }
                    .mask(maskShape)
            } else {
                emptySquare.frame(width: imageSize, height: imageSize)
            }
        }.frame(width: itemSize, height: itemSize)
    }

    var maskShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UX.maskShapeCornerRadius)
    }

    var emptySquare: some View {
        maskShape
            .fill(UX.emptySquareFillColor)
            .background(Color.clear)
    }

    var body: some View {
        VStack {
            // Make a grid with 4 columns
            GeometryReader { provider in
                LazyVGrid(columns: (0..<4).map { _ in GridItem(.flexible(minimum: 0, maximum: .infinity)) },
                          spacing: 0,
                          content: {
                    ForEach(0..<8) { index in
                        if let site = entry.sites[safe: index] {
                            topSitesItem(site, itemSize: provider.size.height / 2)
                        } else {
                            emptySquare
                                .frame(width: provider.size.height / 4, height: provider.size.height / 4)
                        }
                    }
                })
            }.padding(.all)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(UX.widgetBackgroundColor)
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString, invalidCharacters: false)!
    }
}
