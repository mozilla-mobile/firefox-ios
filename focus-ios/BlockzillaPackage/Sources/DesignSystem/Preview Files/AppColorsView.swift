/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct AppColorsView: View {
    var body: some View {
        Form {
            ForEach(AppColor.allCases, id: \.self) { color in
                HStack {
                    Text(color.rawValue)
                    Spacer()
                    Color.init(color.color)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        }
    }
}

@available(iOS 14, *)
struct AppColorsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppColorsView()
                .navigationTitle("App Colors")
        }
    }
}

internal enum AppColor: String, CaseIterable {
    case above
    case accent
    case defaultFont
    case firstRunTitle
    case foundation
    case gradientBackground
    case gradientFirst
    case gradientSecond
    case gradientThird
    case grey10
    case grey30
    case grey50
    case grey70
    case grey90
    case ink90
    case inputPlaceholder
    case launchScreenBackground
    case locationBar
    case magenta40
    case magenta70
    case primaryDark
    case primaryText
    case purple30
    case purple50
    case purple70
    case purple80
    case red60
    case scrim
    case searchGradientFirst
    case searchGradientSecond
    case searchGradientThird
    case searchGradientFourth
    case secondaryText
    case secondaryButton
    case primaryButton
    case searchSuggestionButtonHighlight

    var color: UIColor {
        switch self {
        case .above:
            return .above
        case .accent:
            return .accent
        case .defaultFont:
            return .defaultFont
        case .firstRunTitle:
            return .firstRunTitle
        case .foundation:
            return .foundation
        case .gradientBackground:
            return .gradientBackground
        case .gradientFirst:
            return .gradientFirst
        case .gradientSecond:
            return .gradientSecond
        case .gradientThird:
            return .gradientThird
        case .grey10:
            return .grey10
        case .grey30:
            return .grey30
        case .grey50:
            return .grey50
        case .grey70:
            return .grey70
        case .grey90:
            return .grey90
        case .ink90:
            return .ink90
        case .inputPlaceholder:
            return .inputPlaceholder
        case .launchScreenBackground:
            return .launchScreenBackground
        case .locationBar:
            return .locationBar
        case .magenta40:
            return .magenta40
        case .magenta70:
            return .magenta70
        case .primaryDark:
            return .primaryDark
        case .primaryText:
            return .primaryText
        case .purple30:
            return .purple30
        case .purple50:
            return .purple50
        case .purple70:
            return .purple70
        case .purple80:
            return .purple80
        case .red60:
            return .red60
        case .scrim:
            return .scrim
        case .searchGradientFirst:
            return .searchGradientFirst
        case .searchGradientSecond:
            return .searchGradientSecond
        case .searchGradientThird:
            return .searchGradientThird
        case .searchGradientFourth:
            return .searchGradientFourth
        case .secondaryText:
            return .secondaryText
        case .secondaryButton:
            return .secondaryButton
        case .primaryButton:
            return .primaryButton
        case .searchSuggestionButtonHighlight:
            return .searchSuggestionButtonHighlight
        }
    }
}
