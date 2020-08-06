/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct ImageButtonWithLabel: View {
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
