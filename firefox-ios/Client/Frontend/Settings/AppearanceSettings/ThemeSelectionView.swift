// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct ThemeSelectionView: View {
    let theme: Theme?

    /// The currently selected theme option. Defaults to automatic.
    @State  var selectedThemeOption: ThemeOption = .automatic

    /// Callback executed when a new theme option is selected.
    var onThemeSelected: ((ThemeOption) -> Void)?

    var backgroundColor: Color {
        return Color(theme?.colors.layer2 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 36
        static let sectionPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 0.7
    }

    enum ThemeOption: CaseIterable {
        case automatic
        case light
        case dark

        var rawValue: String {
            switch self {
            case .automatic:
                return String.DisplayThemeAutomaticStatusLabel
            case .light:
                return String.DisplayThemeOptionLight
            case .dark:
                return String.DisplayThemeOptionDark
            }
        }
    }

    var body: some View {
        HStack(spacing: UX.spacing) {
            ForEach(ThemeOption.allCases, id: \.rawValue) { themeOption in
                ThemeOptionView(theme: themeOption, isSelected: selectedThemeOption == themeOption) {
                    selectedThemeOption = themeOption
                    onThemeSelected?(themeOption)
                }
            }
        }
        .padding(.vertical, UX.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }
}
