// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct SearchWidgetView: View {
    let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                .minimumScaleFactor(0.8)
                .foregroundColor(.white)

                Spacer()

                Image.magnifyingGlass
                    .foregroundColor(.white)
                    .frame(height: .magnifyingGlassHeight)
            }
            Spacer()
            HStack {
                Spacer()
                Image.logo
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(height: .logoHeight)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: .quickAccessWidget,
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
    }
}

@available(iOS 14, *)
struct SearchWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SearchWidgetView(title: "Search in Focus")
            .previewLayout(.sizeThatFits)
            .frame(width: 135, height: 135)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

fileprivate extension CGFloat {
    static let logoHeight: CGFloat = 22
    static let magnifyingGlassHeight: CGFloat = 18
}
