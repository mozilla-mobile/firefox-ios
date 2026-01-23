// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import Common

// View for Quick Action Widget Buttons (Small & Medium)
// +-------------------------------------------------------+
// | +--------+                                            |
// | | ZSTACK |                                            |
// | +--------+                                            |
// | +--------------------------------------------------+  |
// | |+-------+                                         |  |
// | ||VSTACK |                                         |  |
// | |+-------+                                         |  |
// | | +---------------------------------------------+  |  |
// | | |+-------+                                    |  |  |
// | | ||HSTACK | +--------+-----+ +--------------+  |  |  |
// | | |+-------+ | VSTACK |     | |+----------+  |  |  |  |
// | | |          +--------+     | || lOGO FOR |  |  |  |  |
// | | |          | +----------+ | ||  WIDGET  |  |  |  |  |
// | | |          | | LABEL OF | | ||  ACTION  |  |  |  |  |
// | | |          | | SELECTED | | |+----------+  |  |  |  |
// | | |          | |  ACTION  | | |              |  |  |  |
// | | |          | +----------+ | |              |  |  |  |
// | | |          |              | |              |  |  |  |
// | | |          +--------------+ +--------------+  |  |  |
// | | |                                             |  |  |
// | | |                                             |  |  |
// | | +---------------------------------------------+  |  |
// | |                                                  |  |
// | | +--------------------------------------------+   |  |
// | | | +--------------------------+ +-----------+ |   |  |
// | | | | HSTACK (if small widget) | | +-------+ | |   |  |
// | | | +--------------------------+ | |FXICON | | |   |  |
// | | |                              | +-------+ | |   |  |
// | | |                              |           | |   |  |
// | | |                              |           | |   |  |
// | | |                              +-----------+ |   |  |
// | | |                                            |   |  |
// | | +--------------------------------------------+   |  |
// | |                                                  |  |
// | |                                                  |  |
// | |                                                  |  |
// | +--------------------------------------------------+  |
// |                                                       |
// +-------------------------------------------------------+

struct ImageButtonWithLabel: View {
    var isSmall: Bool
    var link: QuickLink

    var paddingValue: CGFloat {
        if isSmall {
            return 10.0
        } else {
            return 8.0
        }
    }

    var body: some View {
        let isSearchSmall = (link == .search && isSmall)
        let imageName = isSearchSmall ? StandardImageIdentifiers.Large.search : link.imageName

        Link(destination: isSmall ? link.smallWidgetUrl : link.mediumWidgetUrl) {
            ZStack(alignment: .leading) {
                if !isSmall {
                    if #available(iOS 16.0, *) {
                        BackgroundContent(link: link)
                    } else {
                        ContainerRelativeShape()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: link.backgroundColors),
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            )
                    }
                }

                VStack(alignment: .center, spacing: 50.0) {
                    HStack(alignment: .top) {
                        label
                        Spacer()
                        if #available(iOSApplicationExtension 18.0, *) {
                            Image(decorative: imageName)
                                .widgetAccentedRenderingMode(.accentedDesaturated)
                                .scaledToFit()
                                .frame(height: 24.0)
                        } else {
                            Image(decorative: imageName)
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                    if isSmall {
                        icon
                    }
                }
                .foregroundColor(Color("widgetLabelColors"))
                .padding([.horizontal, .vertical], paddingValue)
            }
        }
    }

    private var label: some View {
        return VStack(alignment: .leading) {
            if isSmall {
                Text(link.label)
                    .font(.headline)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1000)
            } else {
                Text(link.label)
                    .font(.footnote)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1000)
            }
        }
    }

    private var icon: some View {
        return HStack(alignment: .bottom) {
            Spacer()
            if #available(iOSApplicationExtension 18.0, *) {
                Image(decorative: "faviconFox")
                    .widgetAccentedRenderingMode(.accentedDesaturated)
                    .scaledToFit()
                    .frame(height: 24.0)
            } else {
                Image(decorative: "faviconFox")
                    .scaledToFit()
                    .frame(height: 24.0)
            }
        }
    }
}

@available(iOS 16.0, *)
struct BackgroundContent: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    var link: QuickLink

    var body: some View {
        if renderingMode == .accented {
            ContainerRelativeShape()
                .fill(link.tintedBackgroundColor)
        } else {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: link.backgroundColors),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
        }
    }
}
#endif
