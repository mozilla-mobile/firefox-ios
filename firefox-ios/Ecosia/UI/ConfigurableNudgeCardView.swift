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

/// Layout configuration for `ConfigurableNudgeCardView`.
public struct NudgeCardLayout {
    let imageSize: CGFloat
    let closeButtonSize: CGFloat
    let closeButtonPaddingTop: CGFloat
    let closeButtonPaddingLeading: CGFloat
    let closeButtonPaddingBottom: CGFloat
    let closeButtonPaddingTrailing: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let contentPadding: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let titleFont: Font
    let descriptionFont: Font
    let buttonFont: Font
    let buttonTopPadding: CGFloat

    public init(imageSize: CGFloat = 48,
                closeButtonSize: CGFloat = 15,
                closeButtonPaddingTop: CGFloat = 0,
                closeButtonPaddingLeading: CGFloat = 0,
                closeButtonPaddingBottom: CGFloat = 0,
                closeButtonPaddingTrailing: CGFloat = 0,
                horizontalSpacing: CGFloat = .ecosia.space._2s,
                verticalSpacing: CGFloat = .ecosia.space._2s,
                contentPadding: CGFloat = .ecosia.space._m,
                cornerRadius: CGFloat = .ecosia.borderRadius._l,
                borderWidth: CGFloat = 1,
                titleFont: Font = .ecosia(size: .ecosia.font._l, weight: .bold),
                descriptionFont: Font = .ecosia(size: .ecosia.font._m),
                buttonFont: Font = .ecosia(size: .ecosia.font._m),
                buttonTopPadding: CGFloat = .ecosia.space._1s) {
        self.imageSize = imageSize
        self.closeButtonSize = closeButtonSize
        self.closeButtonPaddingTop = closeButtonPaddingTop
        self.closeButtonPaddingLeading = closeButtonPaddingLeading
        self.closeButtonPaddingBottom = closeButtonPaddingBottom
        self.closeButtonPaddingTrailing = closeButtonPaddingTrailing
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.titleFont = titleFont
        self.descriptionFont = descriptionFont
        self.buttonFont = buttonFont
        self.buttonTopPadding = buttonTopPadding
    }

    /// Default layout for standard nudge cards
    public static let `default` = NudgeCardLayout()
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
    let layout: NudgeCardLayout

    public init(title: String,
                description: String? = nil,
                buttonText: String? = nil,
                image: UIImage? = nil,
                showsCloseButton: Bool = true,
                style: NudgeCardStyle,
                layout: NudgeCardLayout = .default) {
        self.title = title
        self.description = description
        self.buttonText = buttonText
        self.image = image
        self.showsCloseButton = showsCloseButton
        self.style = style
        self.layout = layout
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
        HStack(alignment: .top, spacing: viewModel?.layout.horizontalSpacing ?? .ecosia.space._2s) {
            // Image
            if let image = viewModel?.image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: viewModel?.layout.imageSize ?? 48,
                           height: viewModel?.layout.imageSize ?? 48)
                    .accessibilityHidden(true)
            }

            // Text and Action Stack
            VStack(alignment: .leading,
                   spacing: viewModel?.layout.verticalSpacing ?? .ecosia.space._2s) {
                if let title = viewModel?.title {
                    Text(title)
                        .font(viewModel?.layout.titleFont ?? .headline.bold())
                        .foregroundColor(viewModel?.style.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                        .accessibilityLabel(title)
                        .accessibilityIdentifier("nudge_card_title")
                }

                if let description = viewModel?.description {
                    Text(description)
                        .font(viewModel?.layout.descriptionFont ?? .subheadline)
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
                            .font(viewModel?.layout.buttonFont ?? .subheadline)
                            .foregroundColor(viewModel?.style.actionButtonTextColor)
                    }
                    .padding(.top, viewModel?.layout.buttonTopPadding ?? .ecosia.space._1s)
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
                        .frame(width: viewModel?.layout.closeButtonSize ?? 15,
                               height: viewModel?.layout.closeButtonSize ?? 15)
                        .foregroundStyle(viewModel?.style.closeButtonTextColor ?? .primaryText)
                        .accessibilityLabel(String.localized(.configurableNudgeCardCloseButtonAccessibilityLabel))
                        .accessibilityIdentifier("nudge_card_close_button")
                        .accessibilityAddTraits(.isButton)
                }
                .padding(.top, viewModel?.layout.closeButtonPaddingTop ?? 0)
                .padding(.leading, viewModel?.layout.closeButtonPaddingLeading ?? 0)
                .padding(.bottom, viewModel?.layout.closeButtonPaddingBottom ?? 0)
                .padding(.trailing, viewModel?.layout.closeButtonPaddingTrailing ?? 0)
            }
        }
        .onTapGesture {
            delegate?.nudgeCardTapped()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .padding(viewModel?.layout.contentPadding ?? .ecosia.space._m)
        .background(viewModel?.style.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: viewModel?.layout.cornerRadius ?? .ecosia.borderRadius._l))
        .overlay(
            RoundedRectangle(cornerRadius: viewModel?.layout.cornerRadius ?? .ecosia.borderRadius._l)
                .stroke(.border, lineWidth: viewModel?.layout.borderWidth ?? 1)
        )
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
                              actionButtonTextColor: .primaryBrand),
        layout: .default
    )

    ConfigurableNudgeCardView(viewModel: mockViewModel, delegate: nil)
        .padding()
}
