// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A protocol defining actions that can be triggered from a Nudge Card.
public protocol ConfigurableNudgeCardActionDelegate: AnyObject {
    func nudgeCardRequestToPerformAction()
    func nudgeCardRequestToDimiss()
    func nudgeCardTapped()
}

/// A style configuration object for `ConfigurableNudgeCardView`, defining color values for rendering.
public struct NudgeCardStyle {
    let backgroundColor: Color
    let textPrimaryColor: Color
    let textSecondaryColor: Color
    let closeButtonTextColor: Color
    let actionButtonTextColor: Color

    public init(backgroundColor: Color,
                textPrimaryColor: Color,
                textSecondaryColor: Color,
                closeButtonTextColor: Color,
                actionButtonTextColor: Color) {
        self.backgroundColor = backgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.textSecondaryColor = textSecondaryColor
        self.closeButtonTextColor = closeButtonTextColor
        self.actionButtonTextColor = actionButtonTextColor
    }
}

/// A view model containing the content and style information used to render a `ConfigurableNudgeCardView`.
public struct NudgeCardViewModel {
    /// A card must have a title.
    let title: String
    /// Pass `nil` to hide the description text.
    let description: String?
    /// Pass `nil` to hide the bottom action button.
    let buttonText: String?
    /// Pass `nil` to hide the image.
    let image: UIImage?
    let showsCloseButton: Bool
    var style: NudgeCardStyle

    public init(title: String,
                description: String? = nil,
                buttonText: String? = nil,
                image: UIImage? = nil,
                showsCloseButton: Bool = true,
                style: NudgeCardStyle) {
        self.title = title
        self.description = description
        self.buttonText = buttonText
        self.image = image
        self.showsCloseButton = showsCloseButton
        self.style = style
    }
}

/// A SwiftUI view representing a configurable card with optional image, text, action button, and close button.
/// Used in collection view cells like NTP Cards or the Default Browser Card.
public struct ConfigurableNudgeCardView: View {
    var viewModel: NudgeCardViewModel?
    weak var delegate: ConfigurableNudgeCardActionDelegate?

    public init(viewModel: NudgeCardViewModel? = nil,
                delegate: ConfigurableNudgeCardActionDelegate? = nil) {
        self.viewModel = viewModel
        self.delegate = delegate
    }

    public var body: some View {
        HStack(alignment: .top, spacing: .ecosia.space._2s) {
            // Image
            if let image = viewModel?.image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: UX.imageWidthHeight, height: UX.imageWidthHeight)
                    .accessibilityHidden(true)
            }

            // Text and Action Stack
            VStack(alignment: .leading, spacing: .ecosia.space._2s) {
                if let title = viewModel?.title {
                    Text(title)
                        .font(.headline.bold())
                        .foregroundColor(viewModel?.style.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel(title)
                        .accessibilityIdentifier("nudge_card_title")
                }

                if let description = viewModel?.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(viewModel?.style.textSecondaryColor)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel(description)
                        .accessibilityIdentifier("nudge_card_description")
                }

                if let buttonText = viewModel?.buttonText {
                    Button(action: {
                        delegate?.nudgeCardRequestToPerformAction()
                    }) {
                        Text(buttonText)
                            .font(.subheadline)
                            .foregroundColor(viewModel?.style.actionButtonTextColor)
                    }
                    .padding(.top, .ecosia.space._1s)
                    .accessibilityLabel(buttonText)
                    .accessibilityIdentifier("nudge_card_cta_button")
                    .accessibilityAddTraits(.isButton)
                }
            }

            // Close button
            if viewModel?.showsCloseButton == true {
                Button(action: {
                    delegate?.nudgeCardRequestToDimiss()
                }) {
                    Image("close", bundle: .ecosia)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: UX.closeButtonWidthHeight,
                               height: UX.closeButtonWidthHeight)
                        .foregroundStyle(viewModel?.style.closeButtonTextColor ?? .primaryText)
                        .accessibilityLabel(String.localized(.configurableNudgeCardCloseButtonAccessibilityLabel))
                        .accessibilityIdentifier("nudge_card_close_button")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
        .onTapGesture {
            delegate?.nudgeCardTapped()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .padding(.ecosia.space._m)
        .background(viewModel?.style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: .ecosia.borderRadius._l))
        .overlay(
            RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                .stroke(.border, lineWidth: 1)
        )
    }

    // MARK: - UX Constants

    private enum UX {
        static let closeButtonWidthHeight: CGFloat = 15
        static let imageWidthHeight: CGFloat = 48
    }
}

#Preview{
    let mockViewModel = NudgeCardViewModel(
        title: "Make ecosia your default browser app",
        description: "Safely open all links from other apps in Ecosia",
        buttonText: "Take Action",
        image: .init(named: "default-browser-card-side-image-koto-illustrations",
                     in: .ecosia,
                     with: nil),
        style: NudgeCardStyle(backgroundColor: .primaryBackground,
                              textPrimaryColor: .primaryText,
                              textSecondaryColor: .primaryText,
                              closeButtonTextColor: .primaryText,
                              actionButtonTextColor: .primaryBrand)
    )

    ConfigurableNudgeCardView(viewModel: mockViewModel, delegate: nil)
        .padding()
}
