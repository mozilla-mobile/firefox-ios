// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
public struct EcosiaAISearchButton: View {
    private let windowUUID: WindowUUID
    private let onTap: () -> Void

    @State private var theme = EcosiaAISearchButtonTheme()

    public init(
        windowUUID: WindowUUID,
        onTap: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Image("ai-sparkle", bundle: .ecosia)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(theme.iconColor)
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .padding(.ecosia.space._2s)
                .frame(width: .ecosia.space._3l, height: .ecosia.space._3l)
                .background(theme.backgroundColor)
                .cornerRadius(.ecosia.borderRadius._1l)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("AI Search")
        .accessibilityHint("Opens AI search functionality")
        .ecosiaThemed(windowUUID, $theme)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAISearchButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {

            EcosiaAISearchButton(
                windowUUID: .XCTestDefaultUUID,
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
