// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct HelpView: View {
    private struct UX {
        static let padding: CGFloat = 20
        static let textFont = Font.body
        static let imageSize = CGSize(width: 96, height: 96)
    }

    var textColor: UIColor
    var imageColor: UIColor

    let topMessage: String
    let bottomMessage: String?

    var body: some View {
        VStack(alignment: .center, spacing: UX.padding) {
            Image(StandardImageIdentifiers.Large.cloud)
                .renderingMode(.template)
                .resizable()
                .foregroundColor(Color(imageColor))
                .frame(width: UX.imageSize.width, height: UX.imageSize.height)
                .padding(.top, UX.padding)
                .accessibility(hidden: true)
            Text(topMessage)
                .font(UX.textFont)
                .foregroundColor(Color(textColor))
                .multilineTextAlignment(.center)
                .accessibility(identifier: AccessibilityIdentifiers.ShareTo.HelpView.topMessageLabel)

            if let bottomMessage = bottomMessage {
                Text(bottomMessage)
                    .font(UX.textFont)
                    .foregroundColor(Color(textColor))
                    .multilineTextAlignment(.center)
                    .accessibility(identifier: AccessibilityIdentifiers.ShareTo.HelpView.bottomMessageLabel)
            }

            Spacer()
        }
        .padding(UX.padding)
    }
}
