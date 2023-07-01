// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
import UIKit

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
            backgroundColor.color.edgesIgnoringSafeArea(.all)
            ScrollView {
                HelpView(textColor: textColor,
                         imageColor: imageColor,
                         topMessage: String.SendToNotSignedInText,
                         bottomMessage: String.SendToNotSignedInMessage)
            }
        }
        .foregroundColor(Color(textColor))
        .navigationBarItems(leading:
            Button(action: {
                dismissAction?()
            }) {
                Text(String.CloseButtonTitle)
            }
            .accessibility(identifier: AccessibilityIdentifiers.ShareTo.HelpView.doneButton)
        )
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            dismissAction?()
        }
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
