// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Shared

protocol InstructionsViewDelegate: AnyObject {
    func dismissInstructionsView()
}

struct InstructionsView: View {

    private struct UX {
        static let padding: CGFloat = 20
        static let textFont = Font.body
    }

    var backgroundColor: UIColor
    var textColor: UIColor
    var imageColor: UIColor
    var dismissAction: (() -> Void)?

    var body: some View {
        ZStack {
            Color(backgroundColor).edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(alignment: .center, spacing: UX.padding) {
                    Image(ImageIdentifiers.emptySyncImageName)
                        .renderingMode(.template)
                        .foregroundColor(Color(imageColor))
                        .padding(.top, UX.padding)
                        .accessibility(hidden: true)
                    Text(String.SendToNotSignedInText)
                        .font(UX.textFont)
                        .multilineTextAlignment(.center)
                        .accessibility(identifier: AccessibilityIdentifiers.ShareTo.Instructions.notSignedInLabel)
                    Text(String.SendToNotSignedInMessage)
                        .font(UX.textFont)
                        .multilineTextAlignment(.center)
                        .accessibility(identifier: AccessibilityIdentifiers.ShareTo.Instructions.instructionsLabel)

                    Spacer()
                }
                .padding(UX.padding)
            }
        }
        .foregroundColor(Color(textColor))
        .navigationBarItems(leading:
            Button(action: {
                dismissAction?()
            }) {
                Text(String.CloseButtonTitle)
            }
            .accessibility(identifier: AccessibilityIdentifiers.ShareTo.Instructions.doneButton)
        )
        .navigationBarBackButtonHidden(true)
    }
}

struct InstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InstructionsView(backgroundColor: .white,
                             textColor: .darkGray,
                             imageColor: .darkGray)
        }
    }
}
