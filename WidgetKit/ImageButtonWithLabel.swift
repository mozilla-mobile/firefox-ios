/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

// View for Quick Action Widget Buttons (Small & Medium)
//+-------------------------------------------------------+
//| +--------+                                            |
//| | ZSTACK |                                            |
//| +--------+                                            |
//| +--------------------------------------------------+  |
//| |+-------+                                         |  |
//| ||VSTACK |                                         |  |
//| |+-------+                                         |  |
//| | +---------------------------------------------+  |  |
//| | |+-------+                                    |  |  |
//| | ||HSTACK | +--------+-----+ +--------------+  |  |  |
//| | |+-------+ | VSTACK |     | |+----------+  |  |  |  |
//| | |          +--------+     | || lOGO FOR |  |  |  |  |
//| | |          | +----------+ | ||  WIDGET  |  |  |  |  |
//| | |          | | LABEL OF | | ||  ACTION  |  |  |  |  |
//| | |          | | SELECTED | | |+----------+  |  |  |  |
//| | |          | |  ACTION  | | |              |  |  |  |
//| | |          | +----------+ | |              |  |  |  |
//| | |          |              | |              |  |  |  |
//| | |          +--------------+ +--------------+  |  |  |
//| | |                                             |  |  |
//| | |                                             |  |  |
//| | +---------------------------------------------+  |  |
//| |                                                  |  |
//| | +--------------------------------------------+   |  |
//| | | +--------------------------+ +-----------+ |   |  |
//| | | | HSTACK (if small widget) | | +-------+ | |   |  |
//| | | +--------------------------+ | |FXICON | | |   |  |
//| | |                              | +-------+ | |   |  |
//| | |                              |           | |   |  |
//| | |                              |           | |   |  |
//| | |                              +-----------+ |   |  |
//| | |                                            |   |  |
//| | +--------------------------------------------+   |  |
//| |                                                  |  |
//| |                                                  |  |
//| |                                                  |  |
//| +--------------------------------------------------+  |
//|                                                       |
//+-------------------------------------------------------+

struct ImageButtonWithLabel: View {
    var isSmall : Bool
    var link: QuickLink

    var VAlignment: VerticalAlignment {
        if isSmall {
            switch link {
            case .search:
                return .top
            case .privateSearch:
                return .firstTextBaseline
            case .copiedLink:
                return .top
            case .closePrivateTabs:
                return .top
            }
        } else {
            return .top
        }
    }

    var body: some View {
        Link(destination: link.url) {
            ZStack(alignment: .leading) {
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: link.backgroundColors), startPoint: .bottomLeading, endPoint: .topTrailing))
                VStack (alignment: .center, spacing: 50.0){
                    HStack(alignment: VAlignment) {
                        VStack(alignment: .leading){
                            if !isSmall {
                                Text(link.label)
                                    .font(.headline)
                            } else {
                                switch link {
                                case .search:
                                    Text(link.captionText)
                                        .font(.caption).bold()
                                    Text(link.headlineText)
                                        .font(.title).bold()
                                case .privateSearch:
                                    Text(link.headlineText)
                                        .font(.title).bold()
                                    Text(link.captionText)
                                        .font(.caption).bold()
                                default:
                                    Text(link.label)
                                        .font(.headline)
                                }
                            }
                        }
                        Spacer()
                        if link == .search && isSmall {
                            Image("search-button")
                                .scaledToFit()
                                .frame(height: 24.0)
                        } else {
                            Image(link.imageName)
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                    if isSmall {
                        HStack(alignment: .bottom){
                            Spacer()
                            Image("faviconFox")
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                }

                .foregroundColor(Color("widgetLabelColors"))
                .padding(.horizontal, 10.0)
            }
        }
    }
}
