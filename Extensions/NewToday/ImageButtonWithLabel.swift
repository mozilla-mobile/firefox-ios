/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct ImageButtonWithLabel: View {
    var imageName: String
    var url: URL
    var label: String? = ""
    var ButtonGradient: Gradient

    var body: some View {
        Link(destination: url) {
            ZStack(alignment: .leading) {
                ContainerRelativeShape()
                    .fill(LinearGradient(gradient: ButtonGradient , startPoint: .init(x: 1.0, y: 0.0), endPoint: .init(x: 0.0, y: 1.0)))

                HStack(alignment: .top ,content: {
                    if let label = label {
                        Text(label)
                            .font(.headline)
                    }
                    Spacer()
                    Image(imageName)
                        .scaledToFit()
                        .frame(height: 24.0)
                })
                .foregroundColor(Color("widgetLabelColors"))
                .padding(.horizontal, 10.0)
            }
        }
    }
}
