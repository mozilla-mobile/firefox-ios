/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct ImageButtonWithLabel: View {
    var imageName: String
    var url: URL
    var label: String? = ""
    var isPrivate: Bool = false

    var body: some View {
        Link(destination: url) {
            ZStack(alignment: .leading) {
                if isPrivate {
                    ContainerRelativeShape()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color("privateGradientOne"), Color("privateGradientTwo")]), startPoint: .leading, endPoint: .trailing))
                } else {
                    ContainerRelativeShape()
                        .fill(Color("normalBackgroundColor"))
                }

                VStack(alignment: .leading) {
                    Image(imageName)
                        .scaledToFit()
                        .frame(height: 24.0)

                    if let label = label {
                        Text(label)
                            .font(.headline)
                    }
                }
                .foregroundColor(isPrivate ? Color("privateLabelColor") : Color("widgetLabelColors"))
                .padding(.leading, 10.0)
            }
        }
    }
}
