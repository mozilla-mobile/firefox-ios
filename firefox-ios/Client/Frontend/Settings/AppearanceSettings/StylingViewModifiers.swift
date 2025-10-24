// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SectionStyle: ViewModifier {
    let theme: Theme?
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(theme?.colors.layer5 ?? UIColor.clear))
                )
        } else {
            content
        }
    }
}

struct PaddingStyle: ViewModifier {
    let theme: Theme?
    let spacing: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.top, spacing)
                .padding(.horizontal, spacing / 2)
        } else {
            content
                .padding(.top, spacing)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ColoredListStyle: ViewModifier {
    let backgroundColor: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(backgroundColor)
        } else {
            content.listStyle(.plain)
        }
    }
}

struct ListStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.listStyle(.insetGrouped)
        } else {
            content.listStyle(.plain)
        }
    }
}

struct ScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

struct PaddingWithColorStyle: ViewModifier {
    let theme: Theme?
    let spacing: CGFloat
    let shouldChangeBackgroundColor: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.top, spacing)
                .padding(.horizontal, spacing / 2)
        } else {
            if shouldChangeBackgroundColor {
                content
                    .background(theme?.colors.layer5.color)
            } else {
                content
            }
        }
    }
}

struct NewStyleExtraPaddingTopAndBottom: ViewModifier {
    let paddingSize: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.top, paddingSize)
                .padding(.bottom, paddingSize)
        } else {
            content
        }
    }
}

struct NewStyleExtraPadding: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding()
        } else {
            content
        }
    }
}

struct NewStyleRoundedCorners: ViewModifier {
    let topLeadingCorner: CGFloat?
    let topTrailingCorner: CGFloat?
    let bottomLeadingCorner: CGFloat?
    let bottomTrailingCorner: CGFloat?

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: topLeadingCorner ?? 0,
                                           bottomLeadingRadius: bottomLeadingCorner ?? 0,
                                           bottomTrailingRadius: bottomTrailingCorner ?? 0,
                                           topTrailingRadius: topTrailingCorner ?? 0)
                )
        } else {
            content
        }
    }
}

struct ToggleStyle: ViewModifier {
    let paddingSize: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(.top, paddingSize / 2)
                .padding(.bottom, paddingSize / 2)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundColor)
                )
                .padding(.leading, paddingSize)
                .padding(.trailing, paddingSize)
        } else {
            content
                .background(backgroundColor)
        }
    }
}

struct CreditCardViewButtonStyle: ViewModifier {
    let isEnabled: Bool
    let theme: Theme
    let buttonState: CreditCardRightBarButton

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.foregroundColor(getColorForiOS26())
        } else {
            content.foregroundColor(getColorForLegacyiOS())
        }
    }

    private func getColorForiOS26() -> Color {
        if !isEnabled {
            return Color(theme.colors.textSecondary)
        }

        switch buttonState {
        case .edit:
            return Color(theme.colors.textPrimary)
        default:
            return Color(theme.colors.textAccent)
        }
    }

    private func getColorForLegacyiOS() -> Color {
        return isEnabled
            ? Color(theme.colors.actionPrimary)
            : Color(theme.colors.textSecondary)
    }
}
