// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SwiftUI

protocol ToggleModelDelegate: AnyObject {
    func toggleDidChange(_ toggleModel: ToggleModel)
}

class ToggleModel: ObservableObject {
    @Published var isEnabled = false {
        didSet {
            delegate?.toggleDidChange(self)
        }
    }
    weak var delegate: ToggleModelDelegate?

    init(isEnabled: Bool, delegate: ToggleModelDelegate? = nil) {
        self.isEnabled = isEnabled
        self.delegate = delegate
    }
}

struct CreditCardAutofillToggle: View {
    private enum UX {
        static let paddingSize: CGFloat = 4
        static let dividerHeight: CGFloat = 0.7
        static let padding: CGFloat = 16
    }

    // Theming
    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State var textColor: Color = .clear
    @State var backgroundColor: Color = .clear
    @State var toggleTintColor: Color = .clear
    @State var subtitleColor: Color = .clear
    @ObservedObject var model: ToggleModel
    var title: String = .CreditCard.EditCard.ToggleToAllowAutofillTitle
    /// Optional description shown under the title.
    var subtitle: String?

    var body: some View {
        VStack {
            Divider()
                .frame(height: UX.dividerHeight)
                .padding(.leading, UX.padding)
                .hidden()
            HStack {
                toggle
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding(.leading, UX.padding)
                    .padding(.trailing, UX.padding)
                    .modifier(NewStyleExtraPaddingTopAndBottom(paddingSize: UX.paddingSize))
                    .toggleStyle(SwitchToggleStyle(tint: toggleTintColor))
            }
            Divider()
                .frame(height: UX.dividerHeight)
                .padding(.leading, UX.padding)
        }
        .background(backgroundColor)
        .onAppear {
            applyTheme(theme: themeManager.resolveTheme(for: windowUUID, privateOverride: false))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.resolveTheme(for: windowUUID, privateOverride: false))
        }
    }

    @ViewBuilder
    private var toggle: some View {
        if let subtitle {
            Toggle(isOn: $model.isEnabled) {
                VStack(alignment: .leading, spacing: UX.paddingSize) {
                    Text(title)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(subtitleColor)
                }
            }
        } else {
            Toggle(title, isOn: $model.isEnabled)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        subtitleColor = Color(color.textSecondary)
        backgroundColor = Color(theme.isNova ? color.layerSurfaceMedium : color.layer2)
        toggleTintColor = Color(color.actionPrimary)
    }
}

struct CreditCardAutofillToggle_Previews: PreviewProvider {
        static var previews: some View {
            let model = ToggleModel(isEnabled: true)

            CreditCardAutofillToggle(windowUUID: .XCTestDefaultUUID,
                                     textColor: .gray,
                                     model: model)

            CreditCardAutofillToggle(windowUUID: .XCTestDefaultUUID,
                                     textColor: .gray,
                                     model: model)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewDisplayName("Large")

            CreditCardAutofillToggle(windowUUID: .XCTestDefaultUUID,
                                     textColor: .gray,
                                     model: model)
            .environment(\.sizeCategory, .extraSmall)
            .previewDisplayName("Small")
    }
}
