// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Lottie

private struct InstructionStepsViewLayout {
    static let stepNumberWidthHeight: CGFloat = 24
    static let stepsContainerCornerRadius: CGFloat = 10
    static let wavesHeight: CGFloat = 11
}

public struct InstructionStepsViewStyle {
    let backgroundPrimaryColor: Color
    let topContentBackgroundColor: Color
    let stepsBackgroundColor: Color
    let textPrimaryColor: Color
    let textSecondaryColor: Color
    let buttonBackgroundColor: Color
    let buttonTextColor: Color
    let stepRowStyle: StepRowStyle

    public init(backgroundPrimaryColor: Color,
                topContentBackgroundColor: Color,
                stepsBackgroundColor: Color,
                textPrimaryColor: Color,
                textSecondaryColor: Color,
                buttonBackgroundColor: Color,
                buttonTextColor: Color,
                stepRowStyle: StepRowStyle) {
        self.backgroundPrimaryColor = backgroundPrimaryColor
        self.topContentBackgroundColor = topContentBackgroundColor
        self.stepsBackgroundColor = stepsBackgroundColor
        self.textPrimaryColor = textPrimaryColor
        self.textSecondaryColor = textSecondaryColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonTextColor = buttonTextColor
        self.stepRowStyle = stepRowStyle
    }
}

/// A reusable instruction screen with a title, steps, and a CTA button.
struct InstructionStepsView<TopContentView: View>: View {
    let title: String.Key
    let topContentView: TopContentView
    let steps: [InstructionStep]
    let buttonTitle: String.Key
    let onButtonTap: () -> Void
    let style: InstructionStepsViewStyle

    init(title: String.Key,
         steps: [InstructionStep],
         buttonTitle: String.Key,
         onButtonTap: @escaping () -> Void,
         style: InstructionStepsViewStyle,
         @ViewBuilder topContentView: () -> TopContentView) {
        self.title = title
        self.steps = steps
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
        self.style = style
        self.topContentView = topContentView()
    }

    var body: some View {
        ZStack {
            style.backgroundPrimaryColor
                .ignoresSafeArea()
            VStack(spacing: .ecosia.space._1l) {
                ZStack(alignment: .bottom) {
                    style.topContentBackgroundColor
                        .ignoresSafeArea(edges: .top)
                    topContentView
                    Image("wave-forms-horizontal-1", bundle: .ecosia)
                        .resizable()
                        .renderingMode(.template)
                        .frame(height: InstructionStepsViewLayout.wavesHeight)
                        .foregroundStyle(style.backgroundPrimaryColor)
                        .accessibilityHidden(true)
                }

                VStack(spacing: .ecosia.space._1l) {
                    VStack(alignment: .leading,
                           spacing: .ecosia.space._s) {
                        EcosiaText(title)
                            .font(.title2.bold())
                            .foregroundColor(style.textPrimaryColor)
                            .accessibilityIdentifier("instruction_title")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading,
                               spacing: .ecosia.space._s) {
                            renderedSteps
                        }
                    }
                           .frame(maxWidth: .infinity)
                           .padding(.ecosia.space._m)
                           .background(style.stepsBackgroundColor)
                           .cornerRadius(.ecosia.borderRadius._l)

                    Button(action: onButtonTap) {
                        EcosiaText(buttonTitle)
                            .font(.body)
                            .foregroundColor(style.buttonTextColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(style.buttonBackgroundColor)
                    }
                    .clipShape(Capsule())
                    .accessibilityIdentifier("instruction_cta_button")
                    .accessibilityLabel(Text(buttonTitle.rawValue))
                    .accessibilityAddTraits(.isButton)
                }
                .padding([.bottom, .leading, .trailing], .ecosia.space._1l)
            }
        }
    }

    private var renderedSteps: some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { pair in
            let index = pair.offset
            let step = pair.element
            StepRow(index: index, step: step, style: style.stepRowStyle)
        }
    }
}

public struct StepRowStyle {
    let stepNumberColor: Color
    let stepNumberBackgroundColor: Color
    let stepTextColor: Color

    public init(stepNumberColor: Color,
                stepNumberBackgroundColor: Color = .clear,
                stepTextColor: Color) {
        self.stepNumberColor = stepNumberColor
        self.stepNumberBackgroundColor = stepNumberBackgroundColor
        self.stepTextColor = stepTextColor
    }
}

private struct StepRow: View {
    let index: Int
    let step: InstructionStep
    let style: StepRowStyle

    var body: some View {
        HStack(alignment: .center,
               spacing: .ecosia.space._s) {
            Text("\(index + 1)")
                .font(.subheadline.bold())
                .foregroundColor(style.stepNumberColor)
                .frame(width: InstructionStepsViewLayout.stepNumberWidthHeight,
                       height: InstructionStepsViewLayout.stepNumberWidthHeight)
                .background(style.stepNumberBackgroundColor)
                .clipShape(Circle())
                .accessibilityIdentifier("instruction_step_number")

            EcosiaText(step.text)
                .font(.subheadline)
                .foregroundColor(style.stepTextColor)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier("instruction_step_\(index + 1)_text")
        }
        .accessibilityElement(children: .combine)
    }
}

/// A single instruction step with its text.
struct InstructionStep {
    let text: String.Key
}

// MARK: - Preview

#Preview {
    InstructionStepsView(
        title: .defaultBrowserCardDetailTitle,
        steps: [
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep1),
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep2),
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep3)
        ],
        buttonTitle: .defaultBrowserCardDetailButton,
        onButtonTap: {},
        style: InstructionStepsViewStyle(
            backgroundPrimaryColor: .tertiaryBackground,
            topContentBackgroundColor: Color(UIColor(rgb: 0x275243)),
            stepsBackgroundColor: .primaryBackground,
            textPrimaryColor: .primaryText,
            textSecondaryColor: .primaryText,
            buttonBackgroundColor: .primaryBrand,
            buttonTextColor: .primaryBackground,
            stepRowStyle: StepRowStyle(stepNumberColor: .primary,
                                       stepNumberBackgroundColor: .secondary,
                                       stepTextColor: .primaryText)
        )
    ) {
        GeometryReader { geometry in
            VStack {
                Spacer()
                LottieView {
                    try await DotLottieFile.named("default_browser_setup_animation", bundle: .ecosia)
                }
                .configuration(LottieConfiguration(renderingEngine: .mainThread))
                .looping()
                .offset(y: UIDevice.current.userInterfaceIdiom == .pad ? 40 : 18)
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width)
                .clipped()
            }
        }
    }
}
