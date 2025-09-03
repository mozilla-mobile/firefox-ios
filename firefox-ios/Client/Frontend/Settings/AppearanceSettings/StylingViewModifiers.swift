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
                        .fill(Color(theme?.colors.layer2 ?? UIColor.clear))
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
