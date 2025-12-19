// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A reusable avatar component that displays user avatars with cached remote image loading
@available(iOS 16.0, *)
public struct EcosiaAvatar: View {
    private let avatarURL: URL?
    private let size: CGFloat
    private let signedOutPlaceholderImageName: String
    private let signedInPlaceholderImageName: String
    @ObservedObject private var authStateProvider = EcosiaAuthUIStateProvider.shared

    public init(avatarURL: URL?,
                size: CGFloat = .ecosia.space._2l,
                signedOutPlaceholderImageName: String = "avatar",
                signedInPlaceholderImageName: String = "placeholder-trees") {
        self.avatarURL = avatarURL
        self.size = size
        self.signedOutPlaceholderImageName = signedOutPlaceholderImageName
        self.signedInPlaceholderImageName = signedInPlaceholderImageName
    }

    public var body: some View {
        Group {
            EcosiaCachedAsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
            } placeholder: {
                let shouldShowSignedInPlaceholder: Bool = authStateProvider.isLoggedIn && avatarURL == nil
                placeholderView(imageName: shouldShowSignedInPlaceholder ? signedInPlaceholderImageName : signedOutPlaceholderImageName)
                    .transition(.opacity)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityLabel(String.localized(.userAvatarAccessibilityLabel))
            .accessibilityIdentifier("user_avatar")
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.3), value: avatarURL)
    }

    private func placeholderView(imageName: String) -> some View {
        Image(imageName, bundle: .ecosia)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityLabel(String.localized(.defaultAvatarAccessibilityLabel))
            .accessibilityIdentifier("default_avatar")
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            // With remote URL
            EcosiaAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                size: .ecosia.space._6l
            )

            // Without URL (placeholder)
            EcosiaAvatar(
                avatarURL: nil,
                size: .ecosia.space._6l
            )

            // Small size
            EcosiaAvatar(
                avatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4"),
                size: .ecosia.space._2l
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
