// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct OnboardingCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
    public let onLink: () -> Void
//    public let onChoice: (OnboardingMultipleChoiceButtonModel) -> Void

    @Environment(\.theme) private var theme

    public init(
        viewModel: VM,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        onLink: @escaping () -> Void// ,
//        onChoice: @escaping (OnboardingMultipleChoiceButtonModel) -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onLink = onLink
//        self.onChoice = onChoice
    }

    public var body: some View {
        Group {
            switch viewModel.cardType {
            case .basic:
                OnboardingBasicCardView(
                    viewModel: viewModel,
                    onPrimary: onPrimary,
                    onSecondary: onSecondary,
                    onLink: onLink
                )
            case .multipleChoice:
                OnboardingMultipleChoiceCardView(
                    viewModel: viewModel,
                    onPrimary: onPrimary,
                    onSecondary: onSecondary// ,
//                    onChoice: onChoice
                )
            }
        }
        .theme(theme)
    }
}

// MARK: - Basic Card

public struct OnboardingBasicCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
    public let onLink: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    public init(
        viewModel: VM,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        onLink: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onLink = onLink
    }

    // MARK: Layout calculations

    private var imageSize: CGSize {
        let coef: CGFloat = UIDevice.isTiny
            ? 1.0
            : (UIDevice.isSmall ? 1.25 : 1.4)
        let base: CGSize = UIDevice.isTiny
            ? CGSize(width: 144, height: 180)
            : CGSize(width: 240, height: 300)
        return CGSize(width: base.width * coef, height: base.height * coef)
    }

    private var topPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 70 : 90
        } else if UIDevice.isSmall {
            return 40
        } else {
            return UIScreen.main.bounds.height * 0.1
        }
    }

    private var bottomPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? -32 : 0
        }
        return 0
    }

    private var horizontalPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 100 : 24
        }
        return 24
    }

    private var stackSpacing: CGFloat {
        viewModel.link != nil ? 15 : 24
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(UIDevice.isSmall ? .title3 : .title)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    public var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 24) {
                    Spacer()
                    titleView
                    if let uiImage = viewModel.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
                    }
                    bodyView
                    if let link = viewModel.link {
                        LinkButton(
                            viewModel: link,
                            action: onLink
                        )
                    }
                    Spacer()
                    Button(viewModel.buttons.primary.title) {
                        // primary action
                    }
                    .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
                    .buttonStyle(PrimaryButtonStyle())
                }
                .frame(height: 600)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .padding(.horizontal, 24)
                if let sec = viewModel.buttons.secondary {
                    Button(sec.title) {
                        // secondary action
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .accessibility(identifier: "\(viewModel.a11yIdRoot)SecondaryButton")
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Multiple-Choice Card

public struct OnboardingMultipleChoiceCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
//    public let onChoice: (OnboardingMultipleChoiceButtonModel) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var selectedAction: VM.OnboardingMultipleChoiceActionType

    public init(
        viewModel: VM,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
//        onChoice: @escaping (OnboardingMultipleChoiceButtonModel) -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
//        self.onChoice = onChoice
        self._selectedAction = State(initialValue: viewModel.multipleChoiceButtons.first!.action)
    }

    private var imageHeight: CGFloat {
        let coef: CGFloat = UIDevice.isTiny
            ? 1.0
            : (UIDevice.isSmall ? 0.85 : 1.0)
        return 200 * coef
    }

    private var topPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 70 : 90
        } else if UIDevice.isSmall {
            return 40
        } else {
            return UIScreen.main.bounds.height * 0.1
        }
    }

    private var bottomPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? -32 : 0
        }
        return 0
    }

    private var horizontalPadding: CGFloat {
        if UIDevice.isPad {
            return (hSizeClass == .regular) ? 100 : 24
        }
        return 24
    }

    public var body: some View {
        ScrollView {
            VStack {

                Spacer()

                Text(viewModel.title)
                    .font(UIDevice.isSmall ? .title3 : .title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
                    .accessibility(addTraits: .isHeader)

                Spacer()

                OnboardingSegmentedControl<VM.OnboardingMultipleChoiceActionType>(
                    selection: $selectedAction,
                    items: viewModel.multipleChoiceButtons
                )

                Spacer()

                Button(viewModel.buttons.primary.title) {
                    // primary action
                }
                .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(height: 600)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1),
                            radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Helper Button Views

public struct PrimaryRoundedButton: View {
    let title: String
    let accessibilityID: String
    let action: () -> Void
    @Environment(\.theme) private var theme

    public init(title: String, accessibilityID: String, action: @escaping () -> Void) {
        self.title = title
        self.accessibilityID = accessibilityID
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.colors.buttonPrimaryBackground)
                .foregroundColor(theme.colors.buttonPrimaryText)
                .cornerRadius(8)
        }
        .accessibility(identifier: accessibilityID)
    }
}

public struct SecondaryRoundedButton: View {
    let title: String?
    let accessibilityID: String
    let action: () -> Void
    @Environment(\.theme) private var theme

    public init(title: String?, accessibilityID: String, action: @escaping () -> Void) {
        self.title = title
        self.accessibilityID = accessibilityID
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title ?? "")
                .font(.body)
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.colors.buttonSecondaryBorder, lineWidth: 1)
                )
        }
        .accessibility(identifier: accessibilityID)
    }
}

public struct LinkButton: View {
    let viewModel: OnboardingLinkInfoModel
    let action: () -> Void

    public init(viewModel: OnboardingLinkInfoModel, action: @escaping () -> Void) {
        self.viewModel = viewModel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(viewModel.title)
                .underline()
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibility(identifier: viewModel.title)
    }
}

// MARK: - Device-Size Helpers

fileprivate extension UIDevice {
    static var isPad: Bool { current.userInterfaceIdiom == .pad }
    static var isTiny: Bool { UIScreen.main.bounds.height <= 568 }   // ~SE1
    static var isSmall: Bool { UIScreen.main.bounds.height <= 667 || isPad }
}

// MARK: - Shared UX Constants

private struct SharedUX {
    static let topStackSpacing: CGFloat      = 24
    static let smallStackSpacing: CGFloat    = 8
    static let smallScrollPadding: CGFloat   = 20
}
