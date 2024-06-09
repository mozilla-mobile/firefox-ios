// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI
import Storage
import Shared

import struct MozillaAppServices.CreditCard

struct CreditCardItemRow: View {
    let item: CreditCard
    let isAccessibilityCategory: Bool
    let shouldShowSeparator: Bool
    var addPadding: Bool
    var didSelectAction: (() -> Void)?

    // Theming
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State var titleTextColor: Color = .clear
    @State var subTextColor: Color = .clear
    @State var separatorColor: Color = .clear
    @State var backgroundColor: Color = .clear
    @State var backgroundHoverColor: Color = .clear
    @State var isTapping = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            AdaptiveStack(horizontalAlignment: .leading,
                          verticalAlignment: .center,
                          spacing: isAccessibilityCategory ? 5 : 24,
                          isAccessibilityCategory: isAccessibilityCategory) {
                getImage(creditCard: item)
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .aspectRatio(contentMode: .fit)

                getCreditCardContent()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 11)
            .padding(.bottom, 11)
            .background(isTapping ? backgroundHoverColor : backgroundColor)
            .onTapGesture {
                isTapping = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTapping = false
                    didSelectAction?()
                }
            }
            .accessibility(addTraits: .isButton)
            Rectangle()
                .fill(separatorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 0.7)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .opacity(shouldShowSeparator ? 1 : 0)
        }
        .background(ClearBackgroundView())
        .padding(.vertical, addPadding ? 8 : 0)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    func getImage(creditCard: CreditCard) -> Image {
        let defaultImage = Image(decorative: StandardImageIdentifiers.Large.creditCard)

        guard let type = CreditCardType(rawValue: creditCard.ccType.uppercased()),
              let image = type.imageName else {
            return defaultImage
        }

        return Image(decorative: image)
    }

    private func getCreditCardContent() -> some View {
        return VStack(spacing: 0) {
            getCreditCardName()

            getCreditCardNumber()

            AdaptiveStack(horizontalAlignment: .leading,
                          spacing: isAccessibilityCategory ? 0 : 5,
                          isAccessibilityCategory: isAccessibilityCategory) {
                Text(String.CreditCard.DisplayCard.ExpiresLabel)
                    .font(.body)
                    .foregroundColor(subTextColor)
                Text(verbatim: "\(item.ccExpMonth)/\(item.ccExpYear % 100)")
                    .font(.subheadline)
                    .foregroundColor(subTextColor)
            }
            .frame(maxWidth: .infinity,
                   alignment: .leading)
        }
    }

    private func getCreditCardName() -> some View {
        return Text(item.ccName)
            .font(.body)
            .foregroundColor(titleTextColor)
            .frame(maxWidth: .infinity,
                   alignment: .leading)
    }

    private func getCreditCardNumber() -> some View {
        return AdaptiveStack(horizontalAlignment: .leading,
                             spacing: isAccessibilityCategory ? 0 : 5,
                             isAccessibilityCategory: isAccessibilityCategory) {
            Text(item.ccType)
                .font(.body)
                .foregroundColor(titleTextColor)
            Text(verbatim: "••••\(item.ccNumberLast4)")
                .font(.subheadline)
                .foregroundColor(subTextColor)
        }
        .frame(maxWidth: .infinity,
               alignment: .leading)
        .padding(.top, 3)
        .padding(.bottom, 3)
    }

    private func getCreditCardExpiration() -> some View {
        return AdaptiveStack(horizontalAlignment: .leading,
                             spacing: isAccessibilityCategory ? 0 : 5,
                             isAccessibilityCategory: isAccessibilityCategory) {
            Text(String.CreditCard.DisplayCard.ExpiresLabel)
                .font(.body)
                .foregroundColor(subTextColor)
            Text(verbatim: "\(item.ccExpMonth)/\(item.ccExpYear % 100)")
                .font(.subheadline)
                .foregroundColor(subTextColor)
        }
        .frame(maxWidth: .infinity,
               alignment: .leading)
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        separatorColor = Color(color.borderPrimary)
        backgroundColor = Color(color.layer5)
        backgroundHoverColor = Color(color.layer5Hover)
    }
}

struct CreditCardItemRow_Previews: PreviewProvider {
    static var previews: some View {
        let creditCard = CreditCard(guid: "1",
                                    ccName: "Allen Burges",
                                    ccNumberEnc: "1234567891234567",
                                    ccNumberLast4: "4567",
                                    ccExpMonth: 1234567,
                                    ccExpYear: 2023,
                                    ccType: "VISA",
                                    timeCreated: 1234678,
                                    timeLastUsed: nil,
                                    timeLastModified: 123123,
                                    timesUsed: 123123)

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: false,
                          shouldShowSeparator: true,
                          addPadding: true,
                          windowUUID: .XCTestDefaultUUID)

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: true,
                          shouldShowSeparator: true,
                          addPadding: true,
                          windowUUID: .XCTestDefaultUUID)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

        CreditCardItemRow(item: creditCard,
                          isAccessibilityCategory: false,
                          shouldShowSeparator: true,
                          addPadding: true,
                          windowUUID: .XCTestDefaultUUID)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}

// Note: We use a clear view because Color.clear doesn't work
// well if we embed a SwiftUI View inside a UIHostingController
// and it displays black instead of clear color
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
