/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct ImageButtonWithLabelMedium: View {
    var link: QuickLink

    var body: some View {
        Link(destination: link.url) {
            ZStack(alignment: .leading) {
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: link.backgroundColors), startPoint: .bottomLeading, endPoint: .topTrailing))

                HStack(alignment: .top) {
                    Text(link.label)
                        .font(.headline)

                    Spacer()
                    Image(link.imageName)
                        .scaledToFit()
                        .frame(height: 24.0)
                }
                .foregroundColor(Color("widgetLabelColors"))
                .padding(.horizontal, 10.0)
            }
        }
    }
}

struct ImageButtonWithLabelSmall: View {
    var link: QuickLink
    var VAlignment: VerticalAlignment {
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
    }

    var body: some View {
        Link(destination: link.url) {
            ZStack(alignment: .leading) {
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: Gradient(colors: link.backgroundColors), startPoint: .bottomLeading, endPoint: .topTrailing))
                VStack (alignment: .center, spacing: 50.0){
                    HStack(alignment: VAlignment) {
                        VStack(alignment: .leading){
                            switch link {
                            case .search:
                                Text(link.captionTxt)
                                    .font(.caption).bold()
                                Text(link.headlineTxt)
                                    .font(.title).bold()
                            case .privateSearch:
                                Text(link.headlineTxt)
                                    .font(.title).bold()
                                Text(link.captionTxt)
                                    .font(.caption).bold()
                            case .copiedLink:
                                Text(link.label)
                                    .font(.headline)
                            case .closePrivateTabs:
                                Text(link.label)
                                    .font(.headline)
                            }
                        }
                        Spacer()
                        if link == .search {
                            Image("search-button")
                                .scaledToFit()
                                .frame(height: 24.0)
                        } else {
                            Image(link.imageName)
                                .scaledToFit()
                                .frame(height: 24.0)
                        }
                    }
                    
                    HStack(alignment: .bottom){
                        Spacer()
                        Image("faviconFox")
                            .scaledToFit()
                            .frame(height: 24.0)
                    }
                }
                
                .foregroundColor(Color("widgetLabelColors"))
                .padding(.horizontal, 10.0)
            }
        }
    }
}
