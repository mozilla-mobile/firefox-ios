// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

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
    
    var imageView: some View {
        viewModel.image.map {
            Image(uiImage: $0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
            
        }
    }
    
    var linkView: some View {
        viewModel.link.map {
            LinkButton(
                viewModel: $0,
                action: onLink
            )
        }
    }

    var secondaryButton: some View {
        viewModel.buttons.secondary.map {
            Button($0.title) {
                // secondary action
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)SecondaryButton")
        }
    }

    public var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 24) {
                    Spacer()
                    titleView
                    imageView
                    bodyView
                    linkView
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
                secondaryButton
                Spacer()
            }
        }
    }
}
