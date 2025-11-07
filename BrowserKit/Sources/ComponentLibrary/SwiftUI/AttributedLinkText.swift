// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct AttributedLinkText<Action: RawRepresentable>: View where Action.RawValue == String {
    let theme: Theme
    let fullText: String
    let linkText: String
    let action: Action
    let linkAction: (Action) -> Void
    let textAlignment: TextAlignment

    public init(
        theme: Theme,
        fullText: String,
        linkText: String,
        action: Action,
        textAlignment: TextAlignment = .center,
        linkAction: @escaping (Action) -> Void
    ) {
        self.theme = theme
        self.fullText = fullText
        self.linkText = linkText
        self.action = action
        self.linkAction = linkAction
        self.textAlignment = textAlignment
    }

    public var body: some View {
        Text(attributedString)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isLink)
            .accessibilityLabel(fullText)
            .accessibilityAction {
                linkAction(action)
            }
            .font(.caption)
            .multilineTextAlignment(textAlignment)
            .environment(\.openURL, OpenURLAction { url in
                if url.scheme == "action", let host = url.host,
                   let action = Action(rawValue: host) {
                    // Handle in-app navigation
                    linkAction(action)
                    return .handled
                }
                return .systemAction
            })
    }

    private var attributedString: AttributedString {
        var attrString = AttributedString(fullText)
        attrString.foregroundColor = Color(uiColor: theme.colors.textSecondary)

        let actionURL = URL(string: "action://\(action.rawValue)")!
        if let range = attrString.range(of: linkText) {
            attrString[range].underlineStyle = .single
            attrString[range].foregroundColor = Color(uiColor: theme.colors.actionPrimary)
            attrString[range].link = actionURL
        }

        return attrString
    }
}
