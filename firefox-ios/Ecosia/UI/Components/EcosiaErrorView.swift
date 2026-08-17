// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A generic error view component that displays error messages with optional title and subtitle
/// Optionally includes a close button and dismissal callback
@available(iOS 16.0, *)
public struct EcosiaErrorView: View {
    private let title: String?
    private let subtitle: String
    private let windowUUID: WindowUUID
    private let showsCloseButton: Bool
    private let onCloseTapped: (() -> Void)?
    private let onDismiss: (() -> Void)?

    @State private var theme = EcosiaErrorViewTheme()

    private struct UX {
        static let borderWidth: CGFloat = 1
        static let closeButtonSize: CGFloat = 16
    }

    /// Initialize error view with title and subtitle
    /// - Parameters:
    ///   - title: Optional bold title text. If nil, only subtitle is shown
    ///   - subtitle: Main error message text
    ///   - windowUUID: Window UUID for theming
    ///   - showsCloseButton: When true, reserves trailing space for the close button even if it is not interactive.
    ///   - onCloseTapped: Optional closure called when close button is tapped. If nil, close button is hidden.
    ///                    This closure should handle initiating dismissal (e.g., starting animations)
    ///   - onDismiss: Optional closure called when view dismissal is complete (e.g., after animations finish).
    ///                The caller is responsible for calling this at the appropriate time.
    public init(
        title: String? = nil,
        subtitle: String,
        windowUUID: WindowUUID,
        showsCloseButton: Bool = false,
        onCloseTapped: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.windowUUID = windowUUID
        self.showsCloseButton = showsCloseButton || onCloseTapped != nil
        self.onCloseTapped = onCloseTapped
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .center, spacing: .ecosia.space._s) {
            Image.ecosia("problem")
                .resizable()
                .frame(width: .ecosia.space._1l, height: .ecosia.space._1l)
                .foregroundColor(theme.iconColor)
                .accessibilityLabel(String.localized(.ecosiaErrorViewAccessibilityImageLabel))
                .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorView.image)

            textContent
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsCloseButton {
                closeButton
            }
        }
        .padding(.horizontal, .ecosia.space._s)
        .padding(.vertical, .ecosia.space._1s)
        .background(cardBackground)
        .ecosiaThemed(windowUUID, $theme)
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._1s) {
            if let title {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.textPrimaryColor)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(title != nil ? theme.textSecondaryColor : theme.textPrimaryColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var closeButton: some View {
        Button(action: { onCloseTapped?() }) {
            Image.ecosia("close")
                .renderingMode(.template)
                .resizable()
                .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
                .foregroundColor(theme.closeButtonColor)
        }
        .opacity(onCloseTapped != nil ? 1 : 0)
        .disabled(onCloseTapped == nil)
        .accessibilityHidden(onCloseTapped == nil)
        .accessibilityLabel(String.localized(.close))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorView.closeButton)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: .ecosia.borderRadius._m)
            .fill(theme.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: .ecosia.borderRadius._m)
                    .stroke(theme.borderColor, lineWidth: UX.borderWidth)
            )
    }
}

// MARK: - Theme
@available(iOS 16.0, *)
struct EcosiaErrorViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var borderColor = Color.pink
    var textPrimaryColor = Color.black
    var textSecondaryColor = Color.gray
    var iconColor = Color.red
    var closeButtonColor = Color.gray

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundRoleNegative)
        borderColor = Color(theme.colors.ecosia.borderNegative)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        iconColor = Color(theme.colors.ecosia.stateError)
        closeButtonColor = Color(theme.colors.ecosia.buttonContentSecondary)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._l) {
            // With title, subtitle, and close button
            EcosiaErrorView(
                title: String.localized(.couldNotLoadSeedCounter),
                subtitle: String.localized(.couldNotLoadSeedCounterMessage),
                windowUUID: .XCTestDefaultUUID,
                onCloseTapped: { print("Close tapped") },
                onDismiss: { print("Dismissed") }
            )

            // Subtitle only with close button
            EcosiaErrorView(
                subtitle: String.localized(.signInErrorMessage),
                windowUUID: .XCTestDefaultUUID,
                onCloseTapped: { print("Close tapped") }
            )

            // Without close button but with dismiss callback
            EcosiaErrorView(
                title: "Error Title",
                subtitle: "This error view has no close button",
                windowUUID: .XCTestDefaultUUID,
                onDismiss: { print("Dismissed externally") }
            )

            // Long text example with close button
            EcosiaErrorView(
                title: "Error Title",
                subtitle: "This is a longer error message that should wrap to multiple lines to show how the component handles longer text content.",
                windowUUID: .XCTestDefaultUUID,
                onCloseTapped: { print("Close tapped") },
                onDismiss: { print("Dismissed") }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
