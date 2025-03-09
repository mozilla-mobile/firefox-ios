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
        Link(destination: isSmall ? link.smallWidgetUrl : link.mediumWidgetUrl) {
            ZStack(alignment: .leading) {
                if !isSmall {
                    background
                }

                VStack(alignment: .center, spacing: 50.0) {
                    HStack(alignment: .top) {
                        label
                        Spacer()
                        logo
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

    private var background: some View {
        return ContainerRelativeShape()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: link.backgroundColors),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            )
            .widgetAccentableCompat()
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

    private var logo: some View {
        if link == .search && isSmall {
            return Image(decorative: StandardImageIdentifiers.Large.search)
                .scaledToFit()
                .frame(height: 24.0)
        } else {
            return Image(decorative: link.imageName)
                .scaledToFit()
                .frame(height: 24.0)
        }
    }

    private var icon: some View {
        return HStack(alignment: .bottom) {
            Spacer()
            Image(decorative: "faviconFox")
                .scaledToFit()
                .frame(height: 24.0)
        }
    }
}
#endif
