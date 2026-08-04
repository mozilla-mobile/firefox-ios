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
                .widgetTheme()
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName(String.QuickViewGalleryTitle)
        .description(String.QuickViewGalleryDescriptionV2)
        .contentMarginsDisabled()
    }
}

struct OpenTabsView: View {
    let entry: OpenTabsEntry

    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.theme) private var theme

    private var contentColor: Color { Color(uiColor: theme.colors.textPrimary) }

    @ViewBuilder
    func lineItemForTab(_ tab: SimpleTab) -> some View {
        let query = widgetFamily == .systemMedium ? "widget-tabs-medium-open-url" : "widget-tabs-large-open-url"
        VStack(alignment: .leading) {
            Link(destination: linkToContainingApp("?uuid=\(tab.uuid)", query: query)) {
                HStack(alignment: .center, spacing: 15) {
                    if let favIcon = entry.favicons[tab.imageKey] {
                        if #available(iOS 18.0, *) {
                            favIcon.resizable()
                                .widgetAccentedRenderingMode(.accentedDesaturated)
                                .frame(width: 16, height: 16)
                                .foregroundColor(contentColor)
                        } else {
                            favIcon.resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(contentColor)
                        }
                    } else {
                        globeIconView
                    }

                    Text(tab.title ?? "")
                        .foregroundColor(contentColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .regular, design: .default))
                    Spacer()
                }.padding(.horizontal)
            }

            // Separator
            Rectangle()
                .fill(Color(uiColor: theme.colors.borderPrimary))
                .frame(height: 0.5)
                .padding(.leading, 45)
        }
    }

    @ViewBuilder
    private var globeIconView: some View {
        if #available(iOS 18.0, *) {
            Image(decorative: StandardImageIdentifiers.Large.globe)
                .widgetAccentedRenderingMode(.accentedDesaturated)
                .foregroundColor(contentColor)
                .frame(width: 16, height: 16)
        } else {
            Image(decorative: StandardImageIdentifiers.Large.globe)
                .foregroundColor(contentColor)
                .frame(width: 16, height: 16)
        }
    }

    var emptyView: some View {
        VStack {
            Text(String.NoOpenTabsLabel)
                .foregroundStyle(contentColor)
            HStack {
                Spacer()
                Image(decorative: StandardImageIdentifiers.Small.externalLink)
                    .foregroundColor(contentColor)
                Text(String.OpenFirefoxLabel)
                    .foregroundColor(contentColor)
                    .lineLimit(1)
                    .font(.footnote.weight(.semibold))
                Spacer()
            }.padding(10)
        }
    }

    var tabsView: some View {
        VStack(spacing: 8) {
            ForEach(entry.tabs.suffix(numberOfTabsToDisplay), id: \.self) { tab in
                lineItemForTab(tab)
            }

            if entry.tabs.count > numberOfTabsToDisplay {
                HStack(alignment: .center, spacing: 15) {
                    Image(decorative: StandardImageIdentifiers.Small.externalLink)
                        .foregroundColor(contentColor)
                        .frame(width: 16, height: 16)
                    Text(
                        String.localizedStringWithFormat(
                            String.MoreTabsLabel,
                            (entry.tabs.count - numberOfTabsToDisplay)
                        )
                    )
                    .foregroundColor(contentColor)
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

    var openFirefoxButton: some View {
        HStack(alignment: .center, spacing: 15) {
            Image(decorative: StandardImageIdentifiers.Small.externalLink)
                .foregroundColor(contentColor)
            Text(String.OpenFirefoxLabel)
                .foregroundColor(contentColor)
                .lineLimit(1)
                .font(.footnote.weight(.semibold))
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
                emptyView
            } else {
                tabsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(
            LinearGradient(
                gradient: theme.colors.gradientWidgetSurface.swiftUI,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        )
    }

    private func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
        let urlString = "\(scheme)://\(query)\(urlSuffix)"
        return URL(string: urlString)!
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
