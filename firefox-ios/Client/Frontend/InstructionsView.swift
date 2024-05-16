// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI
import UIKit
import Common

protocol InstructionsViewDelegate: AnyObject {
    func dismissInstructionsView()
}

struct InstructionsView: View {
    @Environment(\.colorScheme)
    var colorScheme

    private struct UX {
        static let padding: CGFloat = 20
        static let textFont = Font.body
    }

    var backgroundColor: UIColor
    var textColor: UIColor
    var imageColor: UIColor
    var dismissAction: (() -> Void)?
    var useSystemLightDarkMode = false

    var body: some View {
        if #available(iOS 16.0, *) {
            mainView
            .toolbarBackground(getBackgroundColor().color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        } else {
            mainView
        }
    }

    var mainView: some View {
        ZStack {
            getBackgroundColor().color.edgesIgnoringSafeArea(.all)
            ScrollView {
                HelpView(
                    textColor: getTextColor(),
                    imageColor: getImageColor(),
                    topMessage: String.SendToNotSignedInText,
                    bottomMessage: String.SendToNotSignedInMessage
                )
            }
        }
        .foregroundColor(Color(getTextColor()))
        .navigationBarItems(
            leading: Button(action: { dismissAction?() }) {
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

extension InstructionsView {
    func currentTheme() -> Theme {
        return colorScheme == .dark ? DarkTheme() : LightTheme()
    }

    func getBackgroundColor() -> UIColor {
        if useSystemLightDarkMode {
            return currentTheme().colors.layer2
        }

        return backgroundColor
    }

    func getTextColor() -> UIColor {
        if useSystemLightDarkMode {
            return currentTheme().colors.textPrimary
        }

        return textColor
    }

    func getImageColor() -> UIColor {
        if useSystemLightDarkMode {
            return currentTheme().colors.iconDisabled
        }

        return imageColor
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
