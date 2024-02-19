// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct LoginAutoFillHeaderView: View {
    // Constants for UI layout and styling
    private let headerElementsSpacing: CGFloat = 7.0
    private let mainContainerElementsSpacing: CGFloat = 10
    private let bottomSpacing: CGFloat = 24.0
    private let logoSize: CGFloat = 36.0
    private let closeButtonMarginAndWidth: CGFloat = 46.0
    private let buttonSize: CGFloat = 30

    @Environment(\.themeType)
    var theme

    var title: String
    var header: String

    init(title: String, header: String) {
        self.title = title
        self.header = header
    }

    var body: some View {
        VStack(alignment: .leading, spacing: mainContainerElementsSpacing) {
            HStack {
                Image(uiImage: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: logoSize, height: logoSize)
                    .foregroundColor(.accentColor) // Use your theme's accent color
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                    Text(header)
                        .font(.footnote)
                        .foregroundColor(Color(theme.theme.colors.textSecondary))
                }
                Spacer()
                Button(action: {}) {
                    Image(StandardImageIdentifiers.ExtraLarge.crossCircleFill)
                    .resizable()
                    .frame(
                        width: buttonSize,
                        height: buttonSize
                    )
//                    .foregroundColor(Color(theme.theme.colors.iconSecondary))
//                    .padding(8)
//                    .background(
//                        Circle()
//                            .fill(Color(theme.theme.colors.layer4))
//                    )
                }
            }
        }
        .padding([.leading, .trailing], headerElementsSpacing)
        .padding(.bottom, bottomSpacing)
    }
}

struct LoginAutoFillHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        LoginAutoFillHeaderView(
                title: "Use this login?",
                header: "You’ll sign into cnn.com"
        )
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
