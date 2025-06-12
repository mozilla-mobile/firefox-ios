// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct AttributedLinkText<Action: RawRepresentable>: View where Action.RawValue == String {
    let fullText: String
    let linkText: String
    let action: Action
    let linkAction: (Action) -> Void

    @State private var attributedString: AttributedString

    public init(
        fullText: String,
        linkText: String,
        action: Action,
        linkAction: @escaping (Action) -> Void
    ) {
        self.fullText = fullText
        self.linkText = linkText
        self.action = action
        self.linkAction = linkAction

        var attrString = AttributedString(fullText)
        attrString.foregroundColor = Color(.secondaryLabel)

        let actionURL = URL(string: "action://\(action.rawValue)")!
        if let range = attrString.range(of: linkText) {
            attrString[range].foregroundColor = .blue
            attrString[range].link = actionURL
        }

        self._attributedString = State(initialValue: attrString)
    }

    public var body: some View {
        Text(attributedString)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits([.isStaticText, .isButton])
            .font(.caption)
            .multilineTextAlignment(.center)
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
}
